import pandas as pd
import asyncpg
import asyncio
from pathlib import Path

# Veritabanı ayarları
DB_CONFIG = {
    'user': 'postgres',
    'password': 'molfern',
    'database': 'postwebsocket',
    'host': 'localhost',
    'port': 5432
}

# Dosya yolu ve cihaz-dosya eşlemesi
BASE_DIR = Path("C:/Users/guzel/OneDrive/Masaüstü/appenerji")

DEVICES_EXCEL_FILES = {
    "TV A": {
        "anlik": "TELEVIZYON_anlik_5dk.xlsx",
        "gunluk": "TELEVIZYON_gunluk.xlsx",
        "saatlik": "TELEVIZYON_saatlik.xlsx",
    },
    "Buzdolabi A": {
        "anlik": "BUZDOLABI_anlik_5dk.xlsx",
        "gunluk": "BUZDOLABI_gunluk.xlsx",
        "saatlik": "BUZDOLABI_saatlik.xlsx",
    },
    "Bulasik Makinesi A": {
        "anlik": "BULASIK_anlik_5dk.xlsx",
        "gunluk": "BULASIK_gunluk.xlsx",
        "saatlik": "BULASIK_saatlik.xlsx",
    },
    "Camasir Makinesi A": {
        "anlik": "CAMASIR_anlik_5dk.xlsx",
        "gunluk": "CAMASIR_gunluk.xlsx",
        "saatlik": "CAMASIR_saatlik.xlsx",
    },
}

# Veritabanından device_id al
async def get_device_id(conn, device_name):
    return await conn.fetchval("SELECT id FROM devices WHERE cihaz_adi = $1", device_name)

# Veritabanından son kayıt zamanını al
async def get_latest_time(conn, device_id, table_name):
    return await conn.fetchval(f"SELECT MAX(zaman) FROM {table_name} WHERE device_id = $1", device_id)

# Excel dosyasından veri ekle
async def insert_from_excel(conn, device_id, file_path: str, interval: str, device_name: str):
    try:
        df = pd.read_excel(file_path)
        df.columns = [c.strip().lower() for c in df.columns]
    except Exception as e:
        print(f"❌ [{device_name}] dosya okunamadı: {file_path} - Hata: {e}")
        return

    if interval == "anlik":
        time_col = "timestamp"
        value_col = "power_watt"
        table_name = "power_data"
        insert_field = "power_watt"
    elif interval == "gunluk":
        time_col = "date"
        value_col = "energy_kwh"
        table_name = "daily_energy_data"
        insert_field = "tuketim_kwh"
    elif interval == "saatlik":
        time_col = "hour"
        value_col = "energy_kwh"
        table_name = "hourly_energy_data"
        insert_field = "tuketim_kwh"
    else:
        print(f"⛔ [{device_name}] bilinmeyen veri tipi: {interval}")
        return

    if not all(col in df.columns for col in [time_col, value_col]):
        print(f"⛔ [{device_name}] '{file_path}' dosyasında '{time_col}' veya '{value_col}' sütunu eksik.")
        return

    df[time_col] = pd.to_datetime(df[time_col])
    latest_in_db = await get_latest_time(conn, device_id, table_name)
    if latest_in_db:
        df = df[df[time_col] > latest_in_db]  # Sadece yeni veriler

    if df.empty:
        print(f"ℹ️ [{device_name}] için yeni {interval} verisi yok: {file_path}")
        return

    for _, row in df.iterrows():
        try:
            zaman = row[time_col]
            deger = float(row[value_col])
            await conn.execute(f"""
                INSERT INTO {table_name} (device_id, zaman, {insert_field})
                VALUES ($1, $2, $3)
                ON CONFLICT DO NOTHING
            """, device_id, zaman, deger)
        except Exception as e:
            print(f"⚠️ [{device_name}] satır işlenemedi: {row} - Hata: {e}")

    print(f"✅ [{device_name}] için yeni {interval} veriler eklendi: {file_path}")

# 5 dakikada bir çalışan görev
async def periodic_import():
    while True:
        conn = await asyncpg.connect(**DB_CONFIG)

        for device_name, files in DEVICES_EXCEL_FILES.items():
            device_id = await get_device_id(conn, device_name)
            if not device_id:
                print(f"⛔ Cihaz bulunamadı: {device_name}")
                continue

            for interval, file in files.items():
                full_path = BASE_DIR / file
                if full_path.exists():
                    await insert_from_excel(conn, device_id, str(full_path), interval, device_name)
                else:
                    print(f"❗ [{device_name}] dosya bulunamadı: {full_path}")

        await conn.close()
        await asyncio.sleep(300)  # 5 dakika

# Başlat
if __name__ == "__main__":
    asyncio.run(periodic_import())
