import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'detay_televizyon.dart';
import 'detay_buzdolabi.dart';
import 'detay_bulasik.dart';
import 'detay_camasir.dart';

void main() {
  runApp(const EnergyApp());
}

class EnergyApp extends StatelessWidget {
  const EnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enerji İzleme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DeviceListPage(),
    );
  }
}

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}
class _DeviceListPageState extends State<DeviceListPage> {
  WebSocketChannel? channel; // ✅ nullable tanımlandı

  // Televizyon
  String tvPower = '...';
  String tvEnergy = '...';
  String tvMonthlyEnergy = '...';
  String? tvAdvice;
  List<double> tvHourly = List.filled(24, 0.0);
  List<double> tvDaily = List.filled(30, 0.0);
  List<double> tvYearly = List.filled(12, 0.0);
  // TV için güç verileri
  List<double> tvPowerDaily = List.filled(288, 0.0);
  List<double> tvPowerWeekly = List.filled(168, 0.0);
  List<String> tvYearlyLabels = [];
  List<String> tvPowerWeeklyLabels = [];



  // Buzdolabı
  String fridgePower = '...';
  String fridgeEnergy = '...';
  String fridgeMonthlyEnergy = '...';
  String? fridgeAdvice;
  List<double> fridgeHourly = List.filled(24, 0.0);
  List<double> fridgeDaily = List.filled(30, 0.0);
  List<double> fridgeYearly = List.filled(12, 0.0);
  List<double> fridgePowerDaily = List.filled(288, 0.0);
  List<double> fridgePowerWeekly = List.filled(168, 0.0);
  List<String> fridgeYearlyLabels = [];
  List<String> fridgePowerWeeklyLabels = [];


  // Bulaşık
  String dishwasherPower = '...';
  String dishwasherEnergy = '...';
  String dishwasherMonthlyEnergy = '...';
  String? dishwasherAdvice;
  List<double> dishwasherHourly = List.filled(24, 0.0);
  List<double> dishwasherDaily = List.filled(30, 0.0);
  List<double> dishwasherYearly = List.filled(12, 0.0);
  List<double> dishwasherPowerDaily = List.filled(288, 0.0);
  List<double> dishwasherPowerWeekly = List.filled(168, 0.0);
  List<String> dishwasherYearlyLabels = [];
  List<String> dishwasherPowerWeeklyLabels = [];


  // Çamaşır
  String washerPower = '...';
  String washerEnergy = '...';
  String washerMonthlyEnergy = '...';
  String? washerAdvice;
  List<double> washerHourly = List.filled(24, 0.0);
  List<double> washerDaily = List.filled(30, 0.0);
  List<double> washerYearly = List.filled(12, 0.0);
  List<double> washerPowerDaily = List.filled(288, 0.0);
  List<double> washerPowerWeekly = List.filled(168, 0.0);
  List<String> washerYearlyLabels = [];
  List<String> washerPowerWeeklyLabels = [];



  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8765'));
    channel!.stream.listen((message) {
      print('📥 Gelen mesaj: $message'); // Test log'u
      final List<dynamic> dataList = jsonDecode(message);
      setState(() {
        for (final data in dataList) {
          switch (data['device']) {
            case 'TV A':
              tvPower = data['power'].toString();
              tvEnergy = data['daily_total'].toString();
              tvMonthlyEnergy = data['monthly_total'].toString();
              tvHourly = List<double>.from(data['hourly_energy']);
              tvDaily = List<double>.from(data['daily_energy']);
              tvYearly = List<double>.from(data['yearly_energy'] ?? []);
              tvPowerDaily = List<double>.from(data['power_daily'] ?? []);
              tvPowerWeekly = List<double>.from(data['power_weekly'] ?? []);
              tvYearlyLabels = List<String>.from(data['yearly_labels'] ?? []);
              tvPowerWeeklyLabels = List<String>.from(data['power_weekly_labels'] ?? []);
              tvAdvice = data['ai_advice'];

              break;

            case 'Buzdolabi A':
              fridgePower = data['power'].toString();
              fridgeEnergy = data['daily_total'].toString();
              fridgeMonthlyEnergy = data['monthly_total'].toString();
              fridgeHourly = List<double>.from(data['hourly_energy']);
              fridgeDaily = List<double>.from(data['daily_energy']);
              fridgeYearly = List<double>.from(data['yearly_energy'] ?? []);
              fridgePowerDaily = List<double>.from(data['power_daily'] ?? []);
              fridgePowerWeekly = List<double>.from(data['power_weekly'] ?? []);
              fridgeYearlyLabels = List<String>.from(data['yearly_labels'] ?? []);
              fridgePowerWeeklyLabels = List<String>.from(data['power_weekly_labels'] ?? []);
              fridgeAdvice = data['ai_advice'];

              break;

            case 'Bulasik Makinesi A':
              dishwasherPower = data['power'].toString();
              dishwasherEnergy = data['daily_total'].toString();
              dishwasherMonthlyEnergy = data['monthly_total'].toString();
              dishwasherHourly = List<double>.from(data['hourly_energy']);
              dishwasherDaily = List<double>.from(data['daily_energy']);
              dishwasherYearly = List<double>.from(data['yearly_energy'] ?? []);
              dishwasherPowerDaily = List<double>.from(data['power_daily'] ?? []);
              dishwasherPowerWeekly = List<double>.from(data['power_weekly'] ?? []);
              dishwasherYearlyLabels = List<String>.from(data['yearly_labels'] ?? []);
              dishwasherPowerWeeklyLabels = List<String>.from(data['power_weekly_labels'] ?? []);
              dishwasherAdvice = data['ai_advice'];

              break;

            case 'Camasir Makinesi A':
              washerPower = data['power'].toString();
              washerEnergy = data['daily_total'].toString();
              washerMonthlyEnergy = data['monthly_total'].toString();
              washerHourly = List<double>.from(data['hourly_energy']);
              washerDaily = List<double>.from(data['daily_energy']);
              washerYearly = List<double>.from(data['yearly_energy'] ?? []);
              washerPowerDaily = List<double>.from(data['power_daily'] ?? []);
              washerPowerWeekly = List<double>.from(data['power_weekly'] ?? []);
              washerYearlyLabels = List<String>.from(data['yearly_labels'] ?? []);
              washerPowerWeeklyLabels = List<String>.from(data['power_weekly_labels'] ?? []);
              washerAdvice = data['ai_advice'];

              break;

          }
        }
      });
    });
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cihaz Listesi')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          DeviceCard(
            deviceName: "Televizyon",
            todayEnergy: tvEnergy,
            todayPower: tvPower,
            monthEnergy: tvMonthlyEnergy,
            monthPower: tvPower,
            onMorePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceDetailTelevizyon(
                    power: tvPower,
                    energy: tvEnergy,
                    hourlyData: tvHourly,
                    dailyData: tvDaily,
                    yearlyData: tvYearly,
                    powerDaily: tvPowerDaily,
                    powerWeekly: tvPowerWeekly,
                    yearlyLabels: tvYearlyLabels, powerWeeklyLabels: [],
                    aiAdvice: tvAdvice,


                  ),
                ),
              );
            },
          ),
          DeviceCard(
            deviceName: "Buzdolabı",
            todayEnergy: fridgeEnergy,
            todayPower: fridgePower,
            monthEnergy: fridgeMonthlyEnergy,
            monthPower: fridgePower,
            onMorePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceDetailBuzdolabi(
                    power: fridgePower,
                    energy: fridgeEnergy,
                    hourlyData: fridgeHourly,
                    dailyData: fridgeDaily,
                    yearlyData: fridgeYearly,
                    powerDaily: fridgePowerDaily,
                    powerWeekly: fridgePowerWeekly,
                    yearlyLabels: fridgeYearlyLabels, powerWeeklyLabels: [],
                    aiAdvice: fridgeAdvice,

                  ),
                ),
              );
            },
          ),
          DeviceCard(
            deviceName: "Bulaşık Makinesi",
            todayEnergy: dishwasherEnergy,
            todayPower: dishwasherPower,
            monthEnergy: dishwasherMonthlyEnergy,
            monthPower: dishwasherPower,
            onMorePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceDetailBulasik(
                    power: dishwasherPower,
                    energy: dishwasherEnergy,
                    hourlyData: dishwasherHourly,
                    dailyData: dishwasherDaily,
                    yearlyData: dishwasherYearly,
                    powerDaily: dishwasherPowerDaily,
                    powerWeekly: dishwasherPowerWeekly,
                    yearlyLabels: dishwasherYearlyLabels, powerWeeklyLabels: [],
                    aiAdvice: dishwasherAdvice,

                  ),
                ),
              );
            },
          ),
          DeviceCard(
            deviceName: "Çamaşır Makinesi",
            todayEnergy: washerEnergy,
            todayPower: washerPower,
            monthEnergy: washerMonthlyEnergy,
            monthPower: washerPower,


            onMorePressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeviceDetailCamasir(
                    power: washerPower,
                    energy: washerEnergy,
                    hourlyData: washerHourly,
                    dailyData: washerDaily,
                    yearlyData: washerYearly,
                    powerDaily: washerPowerDaily,
                    powerWeekly: washerPowerWeekly,
                    yearlyLabels: washerYearlyLabels, powerWeeklyLabels: [],
                    aiAdvice: washerAdvice,


                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final String deviceName;
  final String todayEnergy;
  final String todayPower;
  final String monthEnergy;
  final String monthPower;
  final VoidCallback onMorePressed;

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.todayEnergy,
    required this.todayPower,
    required this.monthEnergy,
    required this.monthPower,
    required this.onMorePressed,

  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            ListTile(
              title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: "Bugün"),
                Tab(text: "Bu Ay"),

              ],
            ),
            SizedBox(
              height: 100,
              child: TabBarView(
                children: [
                  _buildInfoContent(todayEnergy, todayPower),
                  _buildInfoContent(monthEnergy, monthPower),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onMorePressed,
              icon: const Icon(Icons.flash_on, color: Colors.blue),
              label: const Text("Daha Fazla Göster", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(String energy, String power) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoItem("Enerji Kullanımı", "$energy kWh"),
          _buildInfoItem("Mevcut Güç", "$power W"),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
