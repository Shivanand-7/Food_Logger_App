class UserInfo {
  final String name;
  final int age;

  UserInfo({required this.name, required this.age});

  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      UserInfo(name: json['name'], age: json['age']);
}
