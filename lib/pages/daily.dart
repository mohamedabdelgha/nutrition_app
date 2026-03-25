import 'package:amazing_icons/amazing_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/customs/custom.dart';
import 'package:flutter_application_1/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyPage extends StatefulWidget {
  final String userId;
  const DailyPage({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => DailyPageState();
}

class DailyPageState extends State<DailyPage> {
  final double width = 7;

  List<BarChartGroupData> rawBarGroups = [];
  List<BarChartGroupData> showingBarGroups = [];

  int touchedGroupIndex = -1;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWeeklyData();
  }

Future<void> loadWeeklyData() async {
  setState(() => loading = true);

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
  final endOfWeek = startOfWeek.add(Duration(days: 7));

  try {
    final response = await Supabase.instance.client
        .from('user_activity')
        .select()
        .eq('userId', widget.userId)
        .gte('created_at', startOfWeek.toIso8601String())
        .lt('created_at', endOfWeek.toIso8601String());

    final data = response as List<dynamic>? ?? [];

    // Weekly = 0..6 (Mon..Sun)
    Map<int, Map<String, double>> weekly = {
      for (int i = 0; i < 7; i++)
        i: {
          'protein': 0.0,
          'Carbohydrate': 0.0,
        }
    };

    for (final row in data) {
      if (row is! Map) continue;

      final createdAt = row['created_at'];
      if (createdAt == null) continue;

      final date = DateTime.tryParse(createdAt);
      if (date == null) continue;

      int dayIndex = date.weekday - 1;
      if (dayIndex < 0 || dayIndex > 6) continue;

      final proteinValue = row['protein'];
      final carbValue = row['Carbohydrate'];

      double protein = (proteinValue is num) ? proteinValue.toDouble() : 0.0;
      double carbs = (carbValue is num) ? carbValue.toDouble() : 0.0;

      weekly[dayIndex]!['protein'] =
          weekly[dayIndex]!['protein']! + protein;

      weekly[dayIndex]!['Carbohydrate'] =
          weekly[dayIndex]!['Carbohydrate']! + carbs;
    }

    // Create chart groups
    final barGroups = List.generate(7, (i) {
      return makeGroupData(
        i,
        weekly[i]!['protein']!,
        weekly[i]!['Carbohydrate']!,
      );
    });

    setState(() {
      rawBarGroups = barGroups;
      showingBarGroups = List.of(barGroups);
      loading = false;
    });
  } catch (e) {
    print("Error fetching weekly data: $e");
    setState(() => loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Daily Activity',
                style: TextStyle(
                    fontFamily: 'main',
                    fontSize: 24,
                    color: AppColors.darkBlueColor,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                AmazingIconOutlined.activity,
                size: 30,
                color: AppColors.darkBlueColor,
              ),
            ),
            Text(
              'Day progress',
              style: TextStyle(
                  fontFamily: 'main',
                  fontSize: 18,
                  color: AppColors.darkBlueColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        DayProgress(userId: widget.userId),
        SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                AmazingIconOutlined.activity,
                size: 30,
                color: AppColors.darkBlueColor,
              ),
            ),
            Text(
              'Week progress',
              style: TextStyle(
                  fontFamily: 'main',
                  fontSize: 18,
                  color: AppColors.darkBlueColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        loading
            ? const Center(child: CircularProgressIndicator())
            : AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            maxY: 250, // adjust as needed
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: ((group) {
                                  return Colors.grey;
                                }),
                                getTooltipItem: (a, b, c, d) => null,
                              ),
                              touchCallback: (FlTouchEvent event, response) {
                                if (response == null || response.spot == null) {
                                  setState(() {
                                    touchedGroupIndex = -1;
                                    showingBarGroups = List.of(rawBarGroups);
                                  });
                                  return;
                                }

                                touchedGroupIndex =
                                    response.spot!.touchedBarGroupIndex;

                                setState(() {
                                  if (!event.isInterestedForInteractions) {
                                    touchedGroupIndex = -1;
                                    showingBarGroups = List.of(rawBarGroups);
                                    return;
                                  }
                                  showingBarGroups = List.of(rawBarGroups);
                                  if (touchedGroupIndex != -1) {
                                    var sum = 0.0;
                                    for (final rod in showingBarGroups[
                                        touchedGroupIndex].barRods) {
                                      sum += rod.toY;
                                    }
                                    final avg = sum /
                                        showingBarGroups[touchedGroupIndex]
                                            .barRods
                                            .length;

                                    showingBarGroups[touchedGroupIndex] =
                                        showingBarGroups[touchedGroupIndex]
                                            .copyWith(
                                      barRods: showingBarGroups[
                                              touchedGroupIndex]
                                          .barRods
                                          .map((rod) {
                                        return rod.copyWith(
                                            toY: avg, color: AppColors.babyBlueColor);
                                      }).toList(),
                                    );
                                  }
                                });
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: bottomTitles,
                                  reservedSize: 42,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 50,
                                  getTitlesWidget: leftTitles,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: showingBarGroups,
                            gridData: const FlGridData(show: true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: AppColors.darkBlueColor,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
    String text = '$value';
    return SideTitleWidget(
      meta: meta,
      space: 0,
      child: Text(text, style: style),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final titles = ['Mn', 'Te', 'Wd', 'Tu', 'Fr', 'St', 'Su'];

    Widget text;
    if (value.toInt() >= 0 && value.toInt() < titles.length) {
      text = Text(
        titles[value.toInt()],
        style: TextStyle(
          color: AppColors.darkBlueColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    } else {
      text = const Text('');
    }

    return SideTitleWidget(
      meta: meta,
      space: 14,
      child: text,
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.darkBlueColor,
          width: width,
        ),
        BarChartRodData(
          toY: y2,
          color: AppColors.babyBlueColor,
          width: width,
        ),
      ],
    );
  }
}
