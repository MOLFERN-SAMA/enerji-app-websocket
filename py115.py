from tapo import ApiClient
import asyncio
import pandas as pd
from datetime import datetime, timedelta

def write_to_excel(file_name, data, sheet_name="Data"):
    try:
        df_existing = pd.read_excel(file_name, sheet_name=sheet_name)
        df_new = pd.concat([df_existing, data], ignore_index=True)
        df_new.to_excel(file_name, sheet_name=sheet_name, index=False)
    except FileNotFoundError:
        data.to_excel(file_name, sheet_name=sheet_name, index=False)

async def monitor_device(client, device_ip, name_prefix):
    try:
        print(f"[{name_prefix}] → Cihaza bağlanılıyor: {device_ip}")
        device = await client.p115(device_ip)
        print(f"[{name_prefix}] → Bağlantı başarılı.")
    except Exception as e:
        print(f"[{name_prefix}] → BAĞLANTI HATASI: {e}")
        return

    anlik_dosya   = f"{name_prefix}_anlik_5dk.xlsx"
    gunluk_dosya  = f"{name_prefix}_gunluk.xlsx"
    saatlik_dosya = f"{name_prefix}_saatlik.xlsx"

    last_logged_hour = None
    last_hour_energy_kwh = None
    last_logged_day = ""
    logged_today = False

    while True:
        try:
            now = datetime.now()
            timestamp      = now.strftime("%Y-%m-%d %H:%M:%S")
            today          = now.strftime("%Y-%m-%d")
            current_hour   = now.strftime("%H")

            if today != last_logged_day:
                logged_today = False
                last_logged_day = today

            power_result = await device.get_current_power()
            power_watt = power_result.current_power
            print(f"[{name_prefix}] {timestamp} → Anlık güç: {power_watt} W")

            anlik_data = pd.DataFrame([[timestamp, power_watt]], columns=["timestamp", "power_watt"])
            write_to_excel(anlik_dosya, anlik_data)

            energy_result = await device.get_energy_usage()
            total_energy_kwh = energy_result.today_energy / 1000

            # Saatlik veri kaydı
            if last_hour_energy_kwh is None:
                last_hour_energy_kwh = total_energy_kwh
                last_logged_hour = current_hour
            elif current_hour != last_logged_hour or (now.hour == 23 and now.minute >= 55):
                saatlik_tuketim_kwh = total_energy_kwh - last_hour_energy_kwh
                if saatlik_tuketim_kwh >= 0:
                    if now.hour == 23 and now.minute >= 55:
                        saatlik_timestamp = now.strftime("%Y-%m-%d") + " 23:59:00"
                    else:
                        saatlik_timestamp = now.strftime("%Y-%m-%d %H:00:00")

                    saatlik_data = pd.DataFrame([[saatlik_timestamp, saatlik_tuketim_kwh]],
                                                columns=["hour", "energy_kwh"])
                    write_to_excel(saatlik_dosya, saatlik_data)
                    print(f"[{name_prefix}] {saatlik_timestamp} → Saatlik tüketim: {saatlik_tuketim_kwh:.3f} kWh")

                last_hour_energy_kwh = total_energy_kwh
                last_logged_hour = current_hour

            # Günlük toplam
            if now.hour == 23 and now.minute >= 55 and not logged_today:
                gunluk_data = pd.DataFrame([[today, total_energy_kwh]], columns=["date", "energy_kwh"])
                write_to_excel(gunluk_dosya, gunluk_data)
                print(f"[{name_prefix}] {today} → Günlük toplam tüketim: {total_energy_kwh:.3f} kWh")
                logged_today = True

            await asyncio.sleep(300)

        except Exception as e:
            print(f"[{name_prefix}] → HATA DÖNGÜ: {e}")
            await asyncio.sleep(10)

async def main():
    client = ApiClient("guzeldemircimolfern@gmail.com", "Molfern4644")
    devices = [
        {"ip": "192.168.1.100", "name": "CAMASIR"},
        {"ip": "192.168.1.101", "name": "BULASIK"},
        # {"ip": "192.168.1.103", "name": "BUZDOLABI"},
        # {"ip": "192.168.1.104", "name": "TELEVIZYON"},
    ]
    await asyncio.gather(*[monitor_device(client, d["ip"], d["name"]) for d in devices])

if __name__ == "__main__":
    print("[GENEL] Uygulama başlatılıyor...")
    asyncio.run(main())
