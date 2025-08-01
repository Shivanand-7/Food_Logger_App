class FoodEntry {
  final String name;
  final String description;
  final DateTime date;

  FoodEntry({
    required this.name,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'date': date.toIso8601String(),
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
    name: json['name'],
    description: json['description'],
    date: DateTime.parse(json['date']),
  );
}
