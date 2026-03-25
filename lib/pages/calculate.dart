import 'dart:convert';
import 'package:amazing_icons/amazing_icons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/customs/custom.dart';
import 'package:flutter_application_1/customs/models.dart';
import 'package:flutter_application_1/main.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalculatePage extends StatefulWidget {
  final String? userId;
  const CalculatePage({super.key, this.userId});

  @override
  State<CalculatePage> createState() => _CalculatePageState();
}

class _CalculatePageState extends State<CalculatePage> {
  late RealtimeChannel _activityChannel;
  final supabase = Supabase.instance.client;
  Map<String, List<Meal>> mealsByDate = {}; // group by date
  bool isLoading = true;

  Map<String, Map<String, double>> nutritionByDate = {};
  // key = date, value = {protein, calories, fat, salt, carbs}
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final userId = widget.userId ?? args?['userId'];

      if (userId == null) {
        print('No userId provided!');
        setState(() {
          isLoading = false;
        });
        return;
      }
      _subscribeToUserActivity(userId);
      fetchUserMeals(userId);
    });
  }

  void showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBlueColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.whiteColor,
                fontFamily: 'main',
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(Duration(seconds: 3)).then((_) => entry.remove());
  }

  void _subscribeToUserActivity(String userId) {
    _activityChannel = supabase.channel('public:user_activity')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all, // listen to insert/update/delete
        schema: 'public',
        table: 'user_activity',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'userId',
          value: userId,
        ),
        callback: (payload) {
          // Whenever user_activity changes, refetch meals
          fetchUserMeals(userId);
        },
      )
      ..subscribe();
  }

  Future<void> fetchUserMeals(String userId) async {
    try {
      // 1. Fetch meals
      final response = await supabase
          .from('user_activity')
          .select('meal, created_at')
          .eq('userId', userId)
          .order('created_at', ascending: false);

      // 2. Fetch daily nutrition totals
      final response1 = await supabase.rpc(
        'get_daily_nutrition',
        params: {'user_id': userId},
      );

      // Store nutrition data
      Map<String, Map<String, double>> nutritionData = {};
      for (var row in response1) {
        final date = row['day'];
        nutritionData[date] = {
          'protein': (row['total_protein'] ?? 0).toDouble(),
          'calories': (row['total_kilocalories'] ?? 0).toDouble(),
          'fats': (row['total_fat'] ?? 0).toDouble(),
          'salt': (row['total_salt'] ?? 0).toDouble(),
          'carbs': (row['total_carbohydrate'] ?? 0).toDouble(),
        };
      }

      // 3. Group meals by date
      Map<String, List<Meal>> groupedMeals = {};
      for (var row in response) {
        final mealData = row['meal'];
        final createdAt = row['created_at'];
        if (mealData == null) continue;

        Map<String, dynamic> decoded;
        if (mealData is String) {
          decoded = jsonDecode(mealData);
        } else if (mealData is Map) {
          decoded = Map<String, dynamic>.from(mealData);
        } else {
          continue;
        }

        final List<dynamic> mealsList = decoded['meals'] ?? [];
        final meals = mealsList.map((m) => Meal.fromJson(m)).toList();

        String dateKey = createdAt != null
            ? DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt))
            : 'Unknown';

        if (!groupedMeals.containsKey(dateKey)) groupedMeals[dateKey] = [];
        groupedMeals[dateKey]!.addAll(meals);
      }

      setState(() {
        mealsByDate = groupedMeals;
        nutritionByDate = nutritionData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching meals: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _activityChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 30,
                      color: AppColors.darkBlueColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'My meals',
                      style: TextStyle(
                        color: AppColors.darkBlueColor,
                        fontFamily: 'main',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        backgroundColor: AppColors.lightBlueColor,
                        color: AppColors.darkBlueColor,
                      ),
                    )
                  : mealsByDate.isEmpty
                  ? const Center(child: Text("No meals found."))
                  : Column(
                      children: mealsByDate.entries.map((entry) {
                        final date = entry.key;
                        final meals = entry.value;
                        final nutrition = nutritionByDate[date] ?? {};
                        return MinimizedContainer(
                          date: date,
                          meals: meals,
                          nutrition: nutrition,
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openMealOptions(context, widget.userId ?? args?['userId']);
        },
        backgroundColor: AppColors.darkBlueColor,
        child: Icon(
          AmazingIconOutlined.addItem,
          size: 30,
          color: AppColors.whiteColor,
        ),
      ),
    );
  }
}

void _openMealOptions(context, String userId) {
  print(userId);
  List<Map<String, dynamic>> selectedMeals = [];
  // TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final form1Key = GlobalKey<FormState>();
  Food? selectedFood;
  double totalFat;
  double totalProtien;
  double totalSalt;
  double totalCarb;
  double totalCalories;
  String allMealNames;

  void addListToSupabase(String type) async {
    allMealNames = selectedMeals.map((meal) => meal['name']).join(" and ");
    totalProtien = selectedMeals.fold(
      0.0,
      (sum, item) => sum + (item['protein'] as num).toDouble(),
    );
    totalCalories = selectedMeals.fold(
      0.0,
      (sum, item) => sum + (item['calories'] as num).toDouble(),
    );
    totalCarb = selectedMeals.fold(
      0.0,
      (sum, item) => sum + (item['carbs'] as num).toDouble(),
    );
    totalFat = selectedMeals.fold(
      0.0,
      (sum, item) => sum + (item['fat'] as num).toDouble(),
    );
    totalSalt = selectedMeals.fold(
      0.0,
      (sum, item) => sum + (item['salt'] as num).toDouble(),
    );
    await supabase.from('user_activity').insert({
      'userId': userId,
      'meal': {
        "meals": [
          {
            "type": type,
            "name": allMealNames,
            "calories": totalCalories,
            "protein_g": totalProtien,
            "salt_g": totalSalt,
            "carb_g": totalCarb,
            "fat_g": totalFat,
          },
        ],
      }, // <-- your JSON
      'date': DateTime.now().toIso8601String(),
      'protien': totalProtien,
      'salt': totalSalt,
      'Kilocalories': totalCalories,
      'fats': totalFat,
      'Carbohydrate': totalCarb,
    });
  }

  //-------------------------------------------------------------------------------------------------------------------------------
  void addMealToList() {
    if (selectedFood == null || amountCtrl.text.isEmpty) {
      print("No food or amount selected");
      return;
    }

    final amount = double.tryParse(amountCtrl.text) ?? 0 / 1000;

    // Calculate nutrition based on amount entered
    final item = {
      "name": selectedFood!.name,
      "amount": amount,
      "protein": selectedFood!.protein * amount / 100,
      "fat": selectedFood!.fat * amount / 100,
      "salt": selectedFood!.salt * amount / 100,
      "calories": selectedFood!.kcal * amount / 100,
      "carbs": selectedFood!.carbs * amount / 100,
    };
    selectedMeals.add(item);
    // Map<String, dynamic> finalJson = {
    //   "meals": selectedMeals,
    // };
    // print(jsonEncode(finalJson));
  }

  //-------------------------------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------------------------------
  String? selectedMealType;
  showModalBottomSheet(
    backgroundColor: AppColors.whiteColor,
    context: context,
    isScrollControlled: true, // full screen height if needed
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets, // handles keyboard
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add a new meal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'main',
                        color: AppColors.darkBlueColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // DropMenuWidget(),
                    const SizedBox(height: 12),
                    DropMenuFoodWidget(
                      onSelected: (food) {
                        selectedFood = food;
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextBox(
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter amount' : null,
                      controller: amountCtrl,
                      hintText: 'Amount (in gram)',
                      labelText: 'Amount',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(AmazingIconOutlined.weight),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate() == false) return;
                        addMealToList();
                        amountCtrl.clear();
                        // Navigator.pop(context);
                      },
                      child: const Text('Add Meal Item'),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: selectedMeals.map((meal) {
                          return SizedBox(
                            width: 150,
                            height: 80,
                            child: GestureDetector(
                              onLongPress: () {
                                selectedMeals.remove(meal);
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 15,
                                ),
                                child: ListTile(
                                  title: Text(meal['name']),
                                  subtitle: Text("${meal['amount']} g\n"),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              selectedMeals.isNotEmpty
                  ? Form(
                      key: form1Key,
                      child: Column(
                        children: [
                          DropdownSearch<String>(
                            items: (filter, loadProps) => [
                              'Breakfast',
                              'Lunch',
                              'dinner',
                            ],
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Enter your meal'
                                : null,
                            mode: Mode.form,
                            decoratorProps: DropDownDecoratorProps(
                              baseStyle: TextStyle(
                                color: AppColors.darkBlueColor,
                              ),
                              // expands:true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.darkBlueColor.withOpacity(
                                  0.08,
                                ),
                                labelText: 'Meal type',
                                labelStyle: TextStyle(
                                  color: AppColors.darkBlueColor,
                                  fontFamily: 'main',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.darkBlueColor,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.darkBlueColor.withOpacity(
                                      0.08,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              menuProps: MenuProps(
                                backgroundColor: AppColors.whiteColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                                color: AppColors.darkBlueColor,
                              ),
                              scrollbarProps: ScrollbarProps(
                                trackBorderColor: AppColors.whiteColor,
                                thumbColor: AppColors.darkBlueColor,
                              ),
                              searchDelay: Duration(milliseconds: 300),
                            ),
                            onChanged: (value) {
                              selectedMealType =
                                  value; // store the selected type
                            },
                          ),
                          // AppTextBox(
                          // validator: (v) => (v == null || v.isEmpty) ? 'Enter Date' : null,
                          // controller: _dateCtrl,
                          // hintText: 'Date',
                          // labelText: 'Date',
                          // keyboardType: TextInputType.datetime,
                          // prefixIcon: Icon(AmazingIconOutlined.calendar),),
                          ElevatedButton(
                            onPressed: () {
                              if (form1Key.currentState!.validate() == false)
                                return;
                              addListToSupabase(selectedMealType ?? '');
                              // _amountCtrl.clear();
                              Navigator.pop(context);
                              showTopSnackBar(
                                context,
                                'your meal has been added successfully ✅, you can see the food nutritions 🎯',
                              );
                            },
                            child: const Text('Add Meal'),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

void showTopSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkBlueColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.whiteColor,
              fontFamily: 'main',
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  Future.delayed(Duration(seconds: 3)).then((_) => entry.remove());
}

class MinimizedContainer extends StatefulWidget {
  final List<Meal> meals;
  final Map<String, double> nutrition; // added
  final String date;
  const MinimizedContainer({
    super.key,
    required this.meals,
    required this.date,
    required this.nutrition,
  });

  @override
  State<MinimizedContainer> createState() => _MinimizedContainerState();
}

class _MinimizedContainerState extends State<MinimizedContainer> {
  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.fastfood;
    }
  }

  bool _isMinimized = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.darkBlueColor),
      ),
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Text(
                      DateFormat(
                        'EEE, MMM d, yyyy',
                      ).format(DateTime.parse(widget.date)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'main',
                        fontSize: 18,
                        color: AppColors.darkBlueColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isMinimized = !_isMinimized;
                      });
                    },
                    icon: Icon(
                      _isMinimized
                          ? AmazingIconOutlined.arrowUp1
                          : AmazingIconOutlined.arrowDown1,
                      size: 25,
                      color: AppColors.darkBlueColor,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Text(
                      'Total Day Nutrition',
                      style: TextStyle(
                        fontFamily: 'main',
                        fontSize: 15,
                        color: AppColors.darkBlueColor,
                      ),
                    ),
                  ],
                ),
              ),
              PieChartSample2(
                text1: 'protien',
                text2: 'carbs',
                text3: 'fats',
                text4: 'salts',
                value1: widget.nutrition['protein'] ?? 0.0,
                value2: widget.nutrition['carbs'] ?? 0.0,
                value3: widget.nutrition['fats'] ?? 0.0,
                value4: widget.nutrition['salt'] ?? 0.0,
              ),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.darkBlueColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedContainer(
            duration: Duration(microseconds: 500),
            width: double.infinity,
            height: _isMinimized ? 0 : null,
            child: _isMinimized
                ? SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: widget.meals.length,
                        itemBuilder: (context, index) {
                          final meal = widget.meals[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            color: Colors.transparent,
                            // shape: RoundedRectangleBorder(
                            //   borderRadius: BorderRadius.circular(12),
                            // ),
                            child: ListTile(
                              leading: Icon(
                                _getMealIcon(meal.type),
                                color: Colors.green,
                                size: 30,
                              ),
                              title: Text(
                                meal.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "${meal.type} • ${meal.calories} kcal • Protein: ${meal.protein}g",
                              ),
                              trailing: Text(
                                "${meal.carbs}g carbs",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
