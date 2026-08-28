import 'package:flutter/material.dart';

class EditProfileProvider extends ChangeNotifier {
  String path = "";
  List<List<dynamic>> items = [];

  void changePath(String value) {
    path = value;
    notifyListeners();
  }

  void changeItems(List<List<dynamic>> value) {
    items = value;
    notifyListeners();
  }
}
