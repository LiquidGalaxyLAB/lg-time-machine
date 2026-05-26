class POI {
  final int? id;
  final int countryId;
  final String name;
  final String description;
  final String imageUrl;

  POI({
    this.id,
    required this.countryId,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'countryId': countryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory POI.fromMap(Map<String, dynamic> map) {
    return POI(
      id: map['id'],
      countryId: map['countryId'],
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
    );
  }
}
