// ...existing code...
import 'dart:ui';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';
import 'package:flutter_application_1/customs/indecator.dart';
import 'package:flutter_application_1/customs/models.dart';
import 'package:flutter_application_1/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



// reusable text box (form field) widget
class AppTextBox extends StatelessWidget {
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final String? labelText;
  final double? bordernum;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextBox({
    super.key,
    this.controller,
    this.bordernum,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.contentPadding, this.inputFormatters, 
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextFormField(
        inputFormatters: inputFormatters,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        onSaved: onSaved,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18),
          suffixIconColor: AppColors.darkBlueColor,
          prefixIconColor: AppColors.darkBlueColor,
          labelText: labelText,
          labelStyle: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.darkBlueColor.withOpacity(0.08),
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(bordernum ?? 8) ,
            borderSide: BorderSide(color: AppColors.darkBlueColor.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(bordernum ?? 8) ,
            borderSide: BorderSide(color: AppColors.darkBlueColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(bordernum ?? 8) ,
            borderSide: BorderSide(color:AppColors.darkBlueColor),
          ),
        ),
      ),
    );
  }
}

//---------------------------------------------------------------

// reusable text box (form field) widget
class ButtonBox extends StatelessWidget {
  final String? labelText;
  final double? width;
  final double? height;
  final VoidCallback? ontap;

  const ButtonBox({
    super.key,
    required this.height,
    required this.width,
    this.labelText,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.all(20.0),
      child: GestureDetector(
        onTap: ontap,
        child: Container(width: width,height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient:LinearGradient(colors: [AppColors.babyBlueColor,AppColors.lightBlueColor,AppColors.darkBlueColor],begin: Alignment.topRight,end: Alignment.bottomLeft,),borderRadius: BorderRadius.circular(50),boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5),blurRadius: 6,offset: const Offset(0, 3))] ),
        child: Text(labelText?? 'none',style: TextStyle(color: AppColors.whiteColor,fontFamily: 'main', fontSize: 25,fontWeight: FontWeight.w600),),),
      ) ,);
  }
}

//---------------------------------------------------------------

// Floating rounded bottom navigation bar
class CustomNavigationBar extends StatelessWidget {
  final List<IconData> icons;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final double height;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;
  final double elevation;

   CustomNavigationBar({
    super.key,
    this.icons = const [Icons.home, Icons.calendar_today, Icons.person],
    this.currentIndex = 0,
    this.onTap,
    this.height = 64,
    this.margin = const EdgeInsets.only(left: 14, right: 14, bottom: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.elevation = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        margin: margin,
        child: Material(
          color: AppColors.whiteColor,
          // elevation: elevation,
          borderRadius: borderRadius,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Container(
              // height: height,
              decoration: BoxDecoration(
                color: AppColors.whiteColor, // semi-transparent background
                borderRadius: borderRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(icons.length, (i) {
                  final selected = i == currentIndex;
                  return IconButton(
                    padding: EdgeInsets.all(15),
                    style: selected? ButtonStyle( backgroundColor: WidgetStateProperty.all(AppColors.darkBlueColor)) : null,
                    onPressed: () => onTap?.call(i),
                    icon: Icon(
                      icons[i],
                      size: selected ? 40 : 30,
                      color: selected ? AppColors.whiteColor : AppColors.darkBlueColor,
                    ),
                    splashRadius: 28,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//---------------------------------------------------------------
class DayProgress extends StatefulWidget {
  final String userId;
  const DayProgress({super.key, required this.userId});

  @override
  State<DayProgress> createState() => _DayProgressState();
}

class _DayProgressState extends State<DayProgress> {
  List<Color> gradientColors = [
    AppColors.darkBlueColor,
    AppColors.lightBlueColor,
    AppColors.babyBlueColor
  ];

  bool showAvg = true;
  bool loading = true;

  List<FlSpot> todaySpots = [];
  double totalCalories = 0.0;

  @override
  void initState() {
    super.initState();
    loadCalories();
  }

Future<void> loadCalories() async {
  setState(() => loading = true);

  try {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final data = await Supabase.instance.client
    .from('user_activity')
    .select()
    .eq('userId', widget.userId)
    .gte('created_at', startOfDay.toIso8601String())
    .lt('created_at', endOfDay.toIso8601String());

    // 'data' is already a List<dynamic>
    List<FlSpot> spots = (data as List<dynamic>).map((item) {
      final time = DateTime.parse(item['created_at']); // make sure column is 'time'
      final calories = (item['Kilocalories'] as num).toDouble();
      final hour = time.hour + time.minute / 60;
      return FlSpot(hour, calories);
    }).toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    double total = spots.fold(0.0, (sum, s) => sum + s.y);

    setState(() {
      todaySpots = spots;
      totalCalories = total;
      loading = false;
    });
  } catch (e) {
    print("Error fetching calories: $e");
    setState(() => loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Stack(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 1.7,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 18,
                  left: 12,
                  top: 24,
                  bottom: 12,
                ),
                child: LineChart(showAvg ? avgData() : mainData()),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: SizedBox(
                width: 60,
                height: 34,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      showAvg = !showAvg;
                    });
                  },
                  child: Text(
                    'avg',
                    style: TextStyle(
                      fontSize: 12,
                      color: showAvg
                          ? AppColors.darkBlueColor.withOpacity(0.5)
                          : AppColors.darkBlueColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "Total Calories Today: ${totalCalories.toStringAsFixed(0)} kcal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.darkBlueColor,
          ),
        ),
      ],
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: false,
        drawVerticalLine: true,
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
            // getTitlesWidget: bottomTitleWidgets,
            reservedSize: 30,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1000, // calories scale, adjust as needed
            // getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: AppColors.darkBlueColor)),
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: todaySpots.isNotEmpty
          ? todaySpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2
          : 100, // max calories scale
      lineBarsData: [
        LineChartBarData(
          spots: todaySpots.isNotEmpty ? todaySpots : [FlSpot(0, 0)],
          isCurved: true,
          gradient: LinearGradient(colors: gradientColors),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors.map((c) => c.withOpacity(0.3)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: true),
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles:
              SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: bottomTitleWidgets),
        ),
        leftTitles: AxisTitles(
          sideTitles:
              SideTitles(showTitles: true, reservedSize: 42, getTitlesWidget: leftTitleWidgets),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: AppColors.darkBlueColor)),
      minX: 0,
      maxX: 24,
      minY: 0,
      maxY: todaySpots.isNotEmpty
          ? todaySpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2
          : 10,
      lineBarsData: [
        LineChartBarData(
          spots: todaySpots.isNotEmpty ? todaySpots : [FlSpot(0, 0)],
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1]).lerp(0.2)!,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // X-axis labels: hour
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    String text = "${value.toInt()}:00";
    return SideTitleWidget(meta: meta, child: Text(text, style: style));
  }

  // Y-axis labels: calories
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    return Text("${value.toInt()}", style: style, textAlign: TextAlign.left);
  }
}
//---------------------------------------------------------------------------------------------------
double calculateBMR({
  required int weightKg,
  required int heightCm,
  required int age,
  required String gender
}) {
  // BMR formula for men
  if(gender == 'male'){
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
  }  return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
}
//---------------------------------------------------------------------------------------------------
  

class PieChartSample2 extends StatefulWidget {
  final String text1;
  final String text2;
  final String text3;
  final String text4;
  final double value1;
  final double value2;
  final double value3;
  final double value4;
  const PieChartSample2({super.key, required this.text1, required this.text2, required this.text3, required this.text4, required this.value1, required this.value2, required this.value3, required this.value4});

  @override
  State<PieChartSample2> createState() => _PieChartSample2State();
}

class _PieChartSample2State extends State<PieChartSample2> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Indicator(
                color: AppColors.darkBlueColor,
                text: widget.text1,
                isSquare: true,
              ),
              const SizedBox(
                height: 4,
              ),
              Indicator(
                color: AppColors.lightBlueColor,
                text: widget.text2,
                isSquare: true,
              ),
              const SizedBox(
                height: 4,
              ),
              Indicator(
                color: AppColors.babyBlueColor,
                text: widget.text3,
                isSquare: true,
              ),
              const SizedBox(
                height: 4,
              ),
              Indicator(
                color: AppColors.blackColor,
                text: widget.text4,
                isSquare: true,
              ),
              const SizedBox(
                height: 18,
              ),
            ],
          ),
          const SizedBox(
            width: 28,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: showingSections(),
                ),
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
  final double totalValues = (widget.value1 + widget.value2 + widget.value3 + widget.value4);
  final double value1Percent = (widget.value1 / totalValues)*100;
  final double value2Percent = (widget.value2 / totalValues)*100;
  final double value3Percent = (widget.value3 / totalValues)*100;
  final double value4Percent = (widget.value4 / totalValues)*100;
    return List.generate(4, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
      return switch (i) {
        0 => PieChartSectionData(
            color: AppColors.darkBlueColor,
            value: value1Percent,
            title: '${widget.value1}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontFamily: 'main',
              shadows: shadows,
            ),
          ),
        1 => PieChartSectionData(
            color: AppColors.lightBlueColor,
            value: value2Percent,
            title: '${widget.value2}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontFamily: 'main',
              shadows: shadows,
            ),
          ),
        2 => PieChartSectionData(
            color: AppColors.babyBlueColor,
            value: value3Percent,
            title: '${widget.value3}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              fontFamily: 'main',
              shadows: shadows,
            ),
          ),
        3 => PieChartSectionData(
            color: AppColors.blackColor,
            value: value4Percent   ,
            title: '${widget.value4}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontFamily: 'main',
              fontWeight: FontWeight.bold,
              color: AppColors.whiteColor,
              shadows: shadows,
            ),
          ),
        _ => throw StateError('Invalid'),
      };
    });
  }
}
class DropMenuFoodWidget extends StatefulWidget {
    final Function(Food?) onSelected;
  const DropMenuFoodWidget({super.key, required this.onSelected });

  @override
  State<DropMenuFoodWidget> createState() => _DropMenuFoodWidgetState();
}

class _DropMenuFoodWidgetState extends State<DropMenuFoodWidget> {
  @override
  Widget build(BuildContext context) {
    return DropdownSearch<Food>(
                  items: (String? filter, LoadProps? loadProps) async {
                    final response = await Supabase.instance.client
                        .from("food")
                        .select();
                      List<Food> foods = response.map<Food>((item) => Food.fromMap(item)).toList();
                    return foods;},
                  validator: (v) => (v == null || v.name.isEmpty) ? 'Enter your meal' : null,
                  itemAsString: (Food f) => f.name,
                  compareFn: (a, b) => a.name == b.name,
                  mode: Mode.form,
                  decoratorProps:DropDownDecoratorProps(
                    baseStyle: TextStyle(color: AppColors.darkBlueColor),
                    // expands:true,
                    decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.darkBlueColor.withOpacity(0.08),
                    labelText: 'choose your meal',
                    labelStyle: TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18,fontWeight: FontWeight.w500),
                    focusedBorder:OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.darkBlueColor,width: 2)
                    ) ,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12) ,
                      borderSide: BorderSide(color: AppColors.darkBlueColor.withOpacity(0.08)),
                    ),
                  ),),
                  popupProps: PopupProps.menu(
                    menuProps: MenuProps(backgroundColor: AppColors.whiteColor,borderRadius: BorderRadius.only(topLeft: Radius.circular(30),topRight: Radius.circular(30)),color: AppColors.darkBlueColor,),
                    title: Center(child: Text('choose your meal',style:TextStyle(color: AppColors.darkBlueColor,fontFamily: 'main',fontSize: 18,fontWeight: FontWeight.w500))),
                    showSearchBox: true,
                    scrollbarProps:ScrollbarProps(trackBorderColor: AppColors.whiteColor,thumbColor: AppColors.darkBlueColor,),
                    searchDelay:Duration(milliseconds: 300),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search...",
                      ),
                    ),
                  ),
                  onChanged: (food) {
                    widget.onSelected(food);
                    
                  },
                );
  }
}