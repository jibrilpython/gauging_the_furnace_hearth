import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gauging_the_furnace_hearth/models/project_model.dart';

class SearchNotifier extends ChangeNotifier {
  String searchQuery = '';

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearSearchQuery() {
    searchQuery = '';
    notifyListeners();
  }

  List<ThermalInstrumentModel> filteredList(List<ThermalInstrumentModel> list) {
    final query = searchQuery.toLowerCase().trim();
    if (query.isEmpty) return list;
    return list.where((item) {
      return item.thermalConeMatrixId.toLowerCase().contains(query) ||
          item.smeltingHearthComplex.toLowerCase().contains(query) ||
          item.deformationTemperatureTarget.toLowerCase().contains(query) ||
          item.era.toLowerCase().contains(query) ||
          item.pyrometricSystem.label.toLowerCase().contains(query) ||
          item.coneMineralFormulation.label.toLowerCase().contains(query) ||
          item.slagColorIndex.label.toLowerCase().contains(query) ||
          item.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }
}

final searchProvider = ChangeNotifierProvider((ref) => SearchNotifier());
