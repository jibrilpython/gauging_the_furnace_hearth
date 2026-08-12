import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNotifier extends ChangeNotifier {
  UserNotifier() {
    loadUser();
  }

  bool firstTimeUser = true;
  static const String _storageKey = 'gfh_user_v1';

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      firstTimeUser = prefs.getBool(_storageKey) ?? true;
    } finally {
      notifyListeners();
    }
  }

  Future<void> setFirstTimeUser(bool value) async {
    firstTimeUser = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
    notifyListeners();
  }
}

final userProvider = ChangeNotifierProvider<UserNotifier>(
  (ref) => UserNotifier(),
);
