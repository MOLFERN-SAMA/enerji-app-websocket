import asyncio
import asyncpg
import json
import websockets
from datetime import datetime
from datetime import datetime, timedelta



DB_CONFIG = {
    'user': 'postgres',
    'password': 'molfern',
    'database': 'postwebsocket',
    'host': 'localhost',
    'port': 5432
}

CIHAZ_TIPLERI = {
    "TV A": "televizyon",
    "Buzdolabi A": "buzdolabi",
    "Bulasik Makinesi A": "bulasik",
    "Camasir Makinesi A": "camasir"
}


CIHAZ_LISTESI = ["TV A", "Buzdolabi A", "Bulasik Makinesi A", "Camasir Makinesi A"]

async def fetch_data(device_name):
    conn = await asyncpg.connect(**DB_CONFIG)

    device_row = await conn.fetchrow(
        "SELECT id FROM devices WHERE cihaz_adi = $1", device_name
    )
    if not device_row:
        await conn.close()
        return {"device": device_name, "error": f"{device_name} cihazı bulunamadı"}

    device_id = device_row['id']
    today = datetime.now().date()
    start_of_month = today.replace(day=1)

    # Anlık güç verisi
    power_row = await conn.fetchrow("""
        SELECT power_watt FROM power_data
        WHERE device_id = $1
        ORDER BY zaman DESC LIMIT 1
    """, device_id)
    power = float(power_row['power_watt']) if power_row else 0.0

    # Günlük toplam
    daily_total_row = await conn.fetchrow("""
        SELECT tuketim_kwh FROM daily_energy_data
        WHERE device_id = $1 AND zaman::date = $2
    """, device_id, today)

    if daily_total_row:
        daily_total = float(daily_total_row['tuketim_kwh'])
    else:
        # Eğer günlük toplam verisi yoksa saatlik verilerin toplamını kullan
        hourly_rows = await conn.fetch("""
            SELECT EXTRACT(HOUR FROM zaman) AS hour, tuketim_kwh
            FROM hourly_energy_data
            WHERE device_id = $1 AND zaman::date = $2
        """, device_id, today)
        
        hourly_energy = [0.0] * 24
        for row in hourly_rows:
            hourly_energy[int(row['hour'])] = float(row['tuketim_kwh'])
        daily_total = round(sum(hourly_energy), 3)


    # Saatlik enerji
    hourly_energy = [0.0] * 24
    hourly_rows = await conn.fetch("""
       SELECT CASE 
                WHEN EXTRACT(HOUR FROM zaman) = 0 THEN 23 
                ELSE EXTRACT(HOUR FROM zaman) - 1 
             END AS hour,
              tuketim_kwh
       FROM hourly_energy_data
       WHERE device_id = $1 AND zaman::date = $2
    """, device_id, today)
    for row in hourly_rows:
        hourly_energy[int(row['hour'])] = float(row['tuketim_kwh'])





    # Günlük enerji (şu aya ait)
    #daily_rows = await conn.fetch("""
    #SELECT zaman::date AS day, tuketim_kwh
    #FROM daily_energy_data
    #WHERE device_id = $1
     # AND date_trunc('month', zaman) = date_trunc('month', current_date)
    #ORDER BY zaman
    #""", device_id)
    #daily_energy = [float(row['tuketim_kwh']) for row in daily_rows]






    # Gün içi toplam (bugün için saatlik enerji verilerinin toplamı)
    today_hourly_total = sum(hourly_energy)

    # Günlük enerji (şu aya ait)
    daily_rows = await conn.fetch("""
        SELECT zaman::date AS day, tuketim_kwh
        FROM daily_energy_data
        WHERE device_id = $1
        AND date_trunc('month', zaman) = date_trunc('month', current_date)
        ORDER BY zaman
    """, device_id)

    daily_energy_list = [float(row['tuketim_kwh']) for row in daily_rows]

    # Bugünün tarihi
    today_date = datetime.now().date()

    # Bugünün verisi varsa güncelle yoksa ekle
    if daily_rows and daily_rows[-1]['day'] == today_date:
        daily_energy_list[-1] = today_hourly_total
    else:
        daily_energy_list.append(today_hourly_total)

    # Sonuç olarak daily_energy_list'i kullan
    daily_energy = daily_energy_list



    # Aylık toplam
    # Aylık toplam tüketim (önce normal yoldan)
    # 1. Önce günlük verilerden toplamaya çalış
    # 1. Bu aya ait günlük verilerin toplamı
    monthly_row = await conn.fetchrow("""
        SELECT SUM(tuketim_kwh) AS total FROM daily_energy_data
        WHERE device_id = $1 AND date_trunc('month', zaman) = date_trunc('month', current_date)
    """, device_id)

    monthly_total = float(monthly_row['total']) if monthly_row and monthly_row['total'] else 0.0

    # 2. Ek olarak: Bugünkü saatlik tüketimi de dahil et
    today_hourly_rows = await conn.fetch("""
        SELECT tuketim_kwh FROM hourly_energy_data
        WHERE device_id = $1 AND zaman::date = CURRENT_DATE
    """, device_id)

    today_total = sum(float(row['tuketim_kwh']) for row in today_hourly_rows)

    # 3. Aylık toplam: önceki günler + bugün (günlük tabloya yazılmamış olabilir)
    monthly_total += today_total
    monthly_total = round(monthly_total, 3)


     # Ay numaralarını Türkçe kısa isimlere eşleyen harita
    # Ay numaralarını Türkçe kısa isimlere eşleyen harita
    ay_label_map = {
        1: "Oca", 2: "Şub", 3: "Mar", 4: "Nis",
        5: "May", 6: "Haz", 7: "Tem", 8: "Ağu",
        9: "Eyl", 10: "Eki", 11: "Kas", 12: "Ara"
    }

    # Aylık toplamları sorgula
    yearly_rows = await conn.fetch("""
        SELECT date_trunc('month', zaman)::date AS ay, SUM(tuketim_kwh) AS toplam
        FROM daily_energy_data
        WHERE device_id = $1
        AND zaman >= date_trunc('year', CURRENT_DATE)
        GROUP BY ay
        ORDER BY ay
    """, device_id)

    # Map olarak tut
    ay_toplam_map = {row['ay'].strftime('%Y-%m'): float(row['toplam']) for row in yearly_rows}

    today = datetime.today()
    this_year = today.year

    yearly_energy = []
    yearly_labels = []

    # Her ay için veriyi sırayla topla, bu ay için daily_total'ı da ekle
    for i in range(1, 13):
        ay_date = datetime(this_year, i, 1)
        key = ay_date.strftime('%Y-%m')
        total = ay_toplam_map.get(key, 0.0)

        # Eğer şu anki ay ise ve bugünkü tüketim varsa onu da ekle
        if i == today.month:
            total += daily_total

        yearly_energy.append(round(total, 4))
        yearly_labels.append(ay_label_map[i])




    # Günlük güç (288)
    power_daily_rows = await conn.fetch("""
        SELECT power_watt FROM power_data
        WHERE device_id = $1 AND zaman >= now() - interval '24 hours'
        ORDER BY zaman
    """, device_id)
    power_daily = [float(row['power_watt']) for row in power_daily_rows]

    # Haftalık güç (168)
    #power_weekly_rows = await conn.fetch("""
    #    SELECT date_trunc('hour', zaman) AS saat, MAX(power_watt) AS max_power
    #    FROM power_data
    #    WHERE device_id = $1 AND zaman >= now() - interval '7 days'
    #    GROUP BY saat
    #    ORDER BY saat
    #""", device_id)
    #power_weekly = [float(row['max_power']) for row in power_weekly_rows]


   
    
    # 1. Saatlik maksimum güç verisini çek
    power_weekly_rows = await conn.fetch("""
        SELECT 
            date_trunc('hour', zaman AT TIME ZONE 'Europe/Istanbul') AS saat,
            MAX(power_watt) AS max_power
        FROM power_data
        WHERE device_id = $1 
        AND zaman >= (NOW() AT TIME ZONE 'Europe/Istanbul') - INTERVAL '7 days'
        GROUP BY saat
        ORDER BY saat
    """, device_id)

    # 2. Sözlük oluştur: {'2025-06-06 13:00:00': 122.0, ...}
    power_map = {
        row['saat'].strftime('%Y-%m-%d %H:00:00'): float(row['max_power'])
        for row in power_weekly_rows
    }

    # 3. Eksik saatleri 0.0 ile tamamla
    now = datetime.now().replace(minute=0, second=0, microsecond=0)
    power_weekly = []
    for i in range(167, -1, -1):
        saat = now - timedelta(hours=i)
        key = saat.strftime('%Y-%m-%d %H:00:00')
        power_weekly.append(power_map.get(key, 0.0))
    
    power_weekly_labels = [
    (now - timedelta(hours=i)).strftime('%Y-%m-%d %H:%M:%S')
    for i in range(167, -1, -1)
    ]



    await conn.close()

    return {
        "device": device_name,
        "power": round(power, 2),
        "daily_total": round(daily_total, 3),
        "monthly_total": round(monthly_total, 3),
        "hourly_energy": [round(x, 3) for x in hourly_energy],
        "daily_energy": [round(x, 3) for x in daily_energy],
        "yearly_energy": [round(x, 3) for x in yearly_energy],
        "power_daily": [round(x, 1) for x in power_daily],
        "yearly_labels": yearly_labels,
        "power_weekly": [round(x, 1) for x in power_weekly],
        "power_weekly_labels": power_weekly_labels,
        #"ai_advice": ai_advice


    }

# WebSocket handler
async def handler(websocket):
    print("📡 WebSocket bağlantısı kuruldu.")
    try:
        while True:
            all_data = []
            for cihaz in CIHAZ_LISTESI:
                data = await fetch_data(cihaz)
                all_data.append(data)
            await websocket.send(json.dumps(all_data, ensure_ascii=False))
            print("📤 Gönderilen veri seti:", json.dumps(all_data, indent=2, ensure_ascii=False))
            await asyncio.sleep(300)
    except Exception as e:
        print("🔥 Hata:", e)

# WebSocket başlat
async def main():
    async with websockets.serve(handler, "0.0.0.0", 8765):
        print("✅ WebSocket sunucusu çalışıyor (port 8765)")
        await asyncio.Future()

asyncio.run(main())
