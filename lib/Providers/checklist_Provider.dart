import 'package:flutter/material.dart';

class TagItem {
  final String name;
  final String type; // "options" or "input"
  final List<String> options;
  String selectedValue; // for both options & input

  TagItem({
    required this.name,
    required this.type,
    required this.options,
    this.selectedValue = "",
  });
}

class ChecklistProvider extends ChangeNotifier {
  final List<TagItem> _tags = [];

  List<TagItem> get tags => _tags;

  // Pehle wala Map<String, String> bhi rakha for saveCheckList compatibility
  Map<String, String> get items {
    return {for (var tag in _tags) tag.name: tag.selectedValue};
  }

  /// Naye API response se tags load karo
  /// tags = List of Map with keys: name, type, options
  void addItemsFromApi(List<dynamic> apiTags) {
    _tags.clear();
    for (var tag in apiTags) {
      _tags.add(TagItem(
        name: tag["name"] ?? "",
        type: tag["type"] ?? "options",
        options:
            tag["options"] != null ? List<String>.from(tag["options"]) : [],
        selectedValue: "",
      ));
    }
    notifyListeners();
  }

  void changeValue(String name, String value) {
    final tag = _tags.firstWhere((t) => t.name == name,
        orElse: () => TagItem(name: "", type: "", options: []));
    if (tag.name.isNotEmpty) {
      tag.selectedValue = value;
      notifyListeners();
    }
  }

  bool areAllTagsSelected() {
    return !_tags.any((tag) => tag.selectedValue.trim().isEmpty);
  }

  void clear() {
    _tags.clear();
    notifyListeners();
  }
}
