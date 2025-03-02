import 'package:flutter/material.dart';

// 1. Create the AppState class (ChangeNotifier)
class AppState extends ChangeNotifier {
  String _currentImagePath = ''; // Store the current image path
  String _currentImageClassofication = ''; // Store the current image classification

  String get currentImagePath => _currentImagePath;
  String get currentImageClassification => _currentImageClassofication;

  set currentImagePath(String value) {
    _currentImagePath = value;
    notifyListeners(); // Important: Notify listeners of the change
  }

  set currentImageClassification(String value) {
    _currentImageClassofication = value;
    notifyListeners(); // Important: Notify listeners of the change
  }
}
