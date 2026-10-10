class OfflineAreaModel {
  final String id;
  final String name;

  OfflineAreaModel({required this.id, required this.name});

  factory OfflineAreaModel.fromJson(Map<String, dynamic> json) {
    return OfflineAreaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class OfflineLocationModel {
  final String id;
  final String name;
  final String description;

  OfflineLocationModel(
      {required this.id, required this.name, required this.description});

  factory OfflineLocationModel.fromJson(Map<String, dynamic> json) {
    return OfflineLocationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
