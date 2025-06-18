import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DeviceDetailBuzdolabi extends StatelessWidget {
  final String power;
  final String energy;
  final List<double> hourlyData;
  final List<double> dailyData;
  final List<double> yearlyData;
  final List<double> powerDaily;
  final List<double> powerWeekly;
  final List<String> yearlyLabels;
  final List<String> powerWeeklyLabels;
  final String? aiAdvice;



  const DeviceDetailBuzdolabi({
    super.key,
    required this.power,
    required this.energy,
    required this.hourlyData,
    required this.dailyData,
    required this.yearlyData,
    required this.powerDaily,
    required this.powerWeekly,
    required this.yearlyLabels,
    required this.powerWeeklyLabels,
    required this.aiAdvice,


  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buzdolabı Makinesi Detay'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Enerji Kullanımı'),
              Tab(text: 'Güç'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EnergyUsageTabBuzdolabi(
              hourlyData: hourlyData,
              dailyData: dailyData,
              yearlyData: yearlyData,
              yearlyLabels: yearlyLabels,
            ),
            _PowerUsageTabBuzdolabi(
              powerDaily: powerDaily,
              powerWeekly: powerWeekly,
              powerWeeklyLabels: powerWeeklyLabels,
            ),
          ],
        ),
      ),
    );
  }
}

// --------- Enerji Sekmesi ---------
class _EnergyUsageTabBuzdolabi extends StatelessWidget {
  final List<double> hourlyData;
  final List<double> dailyData;
  final List<double> yearlyData;
  final List<String> yearlyLabels;



  const _EnergyUsageTabBuzdolabi({
    required this.hourlyData,
    required this.dailyData,
    required this.yearlyData,
    required this.yearlyLabels,


  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour + (now.minute > 0 ? 1 : 0);
    final currentDay = now.day;
    final currentMonth = now.month;

    final todayHourly = hourlyData.take(currentHour.clamp(0, hourlyData.length)).toList();
    final thisMonthDaily = dailyData.take(currentDay.clamp(0, dailyData.length)).toList();
    final thisYearMonthly = yearlyData.take(currentMonth.clamp(0, yearlyData.length)).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0, bottom: const TabBar(
          tabs: [
            Tab(text: 'Gün'),
            Tab(text: 'Ay'),
            Tab(text: 'Yıl'),
          ],
        )),
        body: TabBarView(
          children: [
            _DailyChartBuzdolabi(data: todayHourly),
            _MonthlyChartBuzdolabi(data: thisMonthDaily),
            _YearlyChartBuzdolabi(
              data: yearlyData,
              labels: yearlyLabels,
            ),

          ],
        ),
      ),
    );
  }
}


class _DailyChartBuzdolabi extends StatefulWidget {
  final List<double> data;
  const _DailyChartBuzdolabi({required this.data});
  @override
  State<_DailyChartBuzdolabi> createState() => _DailyChartBuzdolabiState();
}

class _DailyChartBuzdolabiState extends State<_DailyChartBuzdolabi> {
  int? touched;

  @override
  Widget build(BuildContext context) {
    final List<double> completedData = List.generate(
      24,
          (i) => i < widget.data.length ? widget.data[i] : 0.0,
    );

    return Center(
      child: Container(
        height: 320,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            barGroups: List.generate(24, (i) {
              final isTouched = i == touched;
              final originalValue = completedData[i];
              final displayValue = originalValue > 0 ? (originalValue < 0.05 ? 0.05 : originalValue) : 0.001;

              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: displayValue,
                    color: isTouched
                        ? Colors.green
                        : (originalValue > 0 ? Colors.teal : Colors.grey[300]),
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                showingTooltipIndicators: isTouched ? [0] : [],
              );
            }),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final hour = value.toInt();
                    return hour % 3 == 0
                        ? Text('${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontSize: 10))
                        : const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final hour = group.x;
                  final time = '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';
                  final value = '${completedData[hour].toStringAsFixed(3)} kWh';
                  return BarTooltipItem('$time\n$value', const TextStyle(color: Colors.white));
                },
              ),
              touchCallback: (event, response) {
                setState(() {
                  touched = response?.spot?.touchedBarGroupIndex;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}


class _MonthlyChartBuzdolabi extends StatefulWidget {
  final List<double> data;

  const _MonthlyChartBuzdolabi({required this.data});

  @override
  State<_MonthlyChartBuzdolabi> createState() => _MonthlyChartBuzdolabiState();
}

class _MonthlyChartBuzdolabiState extends State<_MonthlyChartBuzdolabi> {
  int? touched;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<double> monthlyData = List.generate(
      30,
          (i) => i < widget.data.length ? widget.data[i] : 0.0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 320,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 24),
                child: BarChart(
                  BarChartData(
                    maxY: monthlyData.reduce((a, b) => a > b ? a : b) * 1.2,
                    barGroups: List.generate(30, (i) {
                      final isTouched = i == touched;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: monthlyData[i],
                            color: isTouched ? Colors.green : Colors.teal,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                        showingTooltipIndicators: isTouched ? [0] : [],
                      );
                    }),
                    titlesData: FlTitlesData(show: false),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = (group.x + 1).toString().padLeft(2, '0');
                          final month = now.month.toString().padLeft(2, '0');
                          final value = '${rod.toY.toStringAsFixed(3)} kWh';
                          return BarTooltipItem('$day.$month\n$value', const TextStyle(color: Colors.white));
                        },
                      ),
                      touchCallback: (event, response) {
                        setState(() {
                          touched = response?.spot?.touchedBarGroupIndex;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 12,
                right: 12,
                child: Container(
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // 🔽 Yapay Zeka Tavsiyesi
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Bazı zamanlarda anlık tüketim yüksek. Kapı açık kalma süresi kontrol edilmeli.",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



class _YearlyChartBuzdolabi extends StatefulWidget {
  final List<double> data;
  final List<String> labels;

  const _YearlyChartBuzdolabi({
    Key? key,
    required this.data,
    required this.labels,
  }) : super(key: key);

  @override
  State<_YearlyChartBuzdolabi> createState() => _YearlyChartBuzdolabiState();
}

class _YearlyChartBuzdolabiState extends State<_YearlyChartBuzdolabi> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 320,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            barGroups: List.generate(widget.data.length, (i) {
              final isTouched = i == touchedIndex;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: widget.data[i],
                    color: isTouched ? Colors.green : Colors.teal,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                showingTooltipIndicators: isTouched ? [0] : [],
              );
            }),
            titlesData: FlTitlesData(
              show: false,
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final index = group.x;
                  final tuketim = rod.toY.toStringAsFixed(2);
                  final ay = index < widget.labels.length ? widget.labels[index] : '';
                  return BarTooltipItem(
                    '$ay\n$tuketim kWh',
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
              touchCallback: (event, response) {
                setState(() {
                  touchedIndex = response?.spot?.touchedBarGroupIndex;
                });
              },
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            // 🔽 ALT ÇİZGİYİ TAM GRAFİK TABANINA KOY
            extraLinesData: ExtraLinesData(horizontalLines: [
              HorizontalLine(
                y: 0, // Bar'ların tabanı
                color: Colors.black,
                strokeWidth: 1.2,
              )
            ]),
          ),
        ),
      ),
    );
  }
}

// --------- Güç Sekmesi ---------
class _PowerUsageTabBuzdolabi extends StatelessWidget {
  final List<double> powerDaily;
  final List<double> powerWeekly;
  final List<String> powerWeeklyLabels;

  const _PowerUsageTabBuzdolabi({
    required this.powerDaily,
    required this.powerWeekly,
    required this.powerWeeklyLabels,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0, bottom: const TabBar(
          tabs: [
            Tab(text: 'Son 24 Saat'),
            Tab(text: 'Son 7 Gün'),
          ],
        )),
        body: TabBarView(
          children: [
            PowerChart24SaatBuzdolabi(data: powerDaily),
            _PowerChart7GunBuzdolabi(data: powerWeekly, labels: powerWeeklyLabels),
          ],
        ),
      ),
    );
  }
}

class PowerChart24SaatBuzdolabi extends StatelessWidget {
  final List<double> data; // 288 veri

  const PowerChart24SaatBuzdolabi({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = List.generate(
      288,
          (i) => FlSpot(i.toDouble(), i < data.length ? data[i] : 0.0),
    );

    final double maxY = data.isNotEmpty
        ? data.reduce((a, b) => a > b ? a : b) + 10
        : 100;

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Buzdolabı: Son 24 Saat Güç Grafiği',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          height: 250,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 60,
                    getTitlesWidget: (value, _) {
                      final hour = (value ~/ 12).toInt();
                      if (value % 60 == 0) {
                        return Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY / 4,
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 4,
                verticalInterval: 60,
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.white,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final dakika = spot.x.toInt() * 5;
                    final saat = (dakika ~/ 60).toString().padLeft(2, '0');
                    final dk = (dakika % 60).toString().padLeft(2, '0');
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} W\n$saat:$dk',
                      const TextStyle(color: Colors.black),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.blueAccent,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// Güncellenmiş ve optimize edilmiş çamaşır makinesi 7 günlük güç grafiği
// Noktasız, düzgün ölçekli, 0 altına düşmeyen çizgi grafik

class _PowerChart7GunBuzdolabi extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  const _PowerChart7GunBuzdolabi({
    required this.data,
    required this.labels,

  });

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    maxY = maxY == 0 ? 10 : (maxY * 1.1).ceilToDouble();

    final now = DateTime.now();

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('Buzdolabı: Son 7 Gün Güç Grafiği',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          height: 250,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 288, // her gün
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      final dt = now.subtract(Duration(minutes: 5 * (data.length - index)));
                      const labels = ['Pzt', 'Sal', 'Çrş', 'Per', 'Cum', 'Cts', 'Paz'];
                      return Text(labels[dt.weekday - 1], style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 4,
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxY / 4,
                verticalInterval: 288,
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.white,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final dt = now.subtract(Duration(minutes: 5 * (data.length - spot.x.toInt())));
                    final gun = ['Pzt', 'Sal', 'Çrş', 'Per', 'Cum', 'Cts', 'Paz'][dt.weekday - 1];
                    final saat = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(0)} W\n$gun $saat',
                      const TextStyle(color: Colors.black),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.blueAccent,
                  barWidth: 1.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

