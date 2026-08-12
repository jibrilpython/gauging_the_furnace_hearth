import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageNotifier extends ChangeNotifier {
  ImageNotifier() {
    _initializeDocumentsPath();
  }

  String _resultImage = '';
  String get resultImage => _resultImage;
  set resultImage(String value) {
    _resultImage = value;
    notifyListeners();
  }

  String? _documentsPath;

  String? getImagePath(String? storedPath) {
    if (_documentsPath == null || storedPath == null || storedPath.isEmpty) {
      return null;
    }
    if (File(storedPath).isAbsolute) {
      return storedPath;
    }
    final fileName = storedPath.split('/').last;
    return fileName.isEmpty ? null : '$_documentsPath/$fileName';
  }

  Future<void> _initializeDocumentsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    _documentsPath = appDir.path;
    notifyListeners();
  }

  Future<void> pickImage({required ImageSource source}) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fullPath =
        '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(pickedFile.path).copy(fullPath);
    resultImage = fullPath;
  }

  void clearImage() => resultImage = '';
}

final imageProvider = ChangeNotifierProvider<ImageNotifier>(
  (ref) => ImageNotifier(),
);
