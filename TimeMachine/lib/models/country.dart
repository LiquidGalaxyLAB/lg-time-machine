class Country {
  final int? id;
  final String name;
  final String flag;

  Country({this.id, required this.name, required this.flag});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'flag': flag,
    };
  }

  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      id: map['id'],
      name: map['name'],
      flag: map['flag'],
    );
  }
}
