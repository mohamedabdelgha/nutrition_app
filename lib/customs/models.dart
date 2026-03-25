class Meal {
  final String name;
  final String type;
  final double fat;
  final double carbs;
  final double calories;
  final double protein;

  Meal({
    required this.name,
    required this.type,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.protein,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      fat: (json['fat_g'] ?? 0).toDouble(),
      carbs: (json['carbs_g'] ?? 0).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein_g'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'fat_g': fat,
      'carbs_g': carbs,
      'calories': calories,
      'protein_g': protein,
    };
  }
}

// ---------------------------------------------------------------------------------------
class Food {
  final String name;
  final double protein;
  // final double carbs;
  final double fat;
  final double salt;
  final double kcal;
  final double carbs;

  Food({
    required this.name,
    required this.protein,
    // required this.carbs,
    required this.fat,
    required this.salt,
    required this.kcal,
    required this.carbs,
  });


  factory Food.fromMap(Map<String, dynamic> map) {
    double toDoubleSafe(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return Food(
      name: map["Category"] ?? "",
      protein: toDoubleSafe(map["Data.Protein"]),
      salt: toDoubleSafe(map["Data.Fat.Saturated Fat"]),
      fat: toDoubleSafe(map["Data.Major Minerals.Sodium"]/10),
      kcal: toDoubleSafe(map["Data.Kilocalories"]),
      carbs: toDoubleSafe(map["Data.Carbohydrate"]),
    );
    
    }
}
