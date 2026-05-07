import 'dart:io';
import 'package:flutter/material.dart';

class ChecklistProvider with ChangeNotifier {
  String? status; // Holds the status value (Resolved or Not Resolved)
  File? resolveImage; // Holds the selected resolve image file
  File? voiceFile; // ✅ NEW: Holds the voice recording file (WAV format)

  // Set status value and notify listeners
  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  // Set the resolve image file and notify listeners
  void setResolveImage(File image) {
    resolveImage = image;
    notifyListeners();
  }

  // ✅ NEW: Set the voice file and notify listeners
  void setVoiceFile(File voice) {
    voiceFile = voice;
    notifyListeners();
  }

  // ✅ UPDATED: Clear voice file without affecting other fields
  void clearVoiceFile() {
    voiceFile = null;
    notifyListeners();
  }

  // ✅ UPDATED: Reset provider state (now includes voice file)
  void reset() {
    status = null;
    resolveImage = null;
    voiceFile = null; // ✅ Reset voice file
    notifyListeners();
  }
}
