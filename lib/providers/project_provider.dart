import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gauging_the_furnace_hearth/models/project_model.dart';
import 'package:gauging_the_furnace_hearth/providers/image_provider.dart';
import 'package:gauging_the_furnace_hearth/providers/input_provider.dart';
import 'package:gauging_the_furnace_hearth/utils/const.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ProjectNotifier extends ChangeNotifier {
  ProjectNotifier() {
    loadEntries();
  }

  List<ThermalInstrumentModel> entries = [];
  bool isLoading = true;
  int stateVersion = 0;
  static const String _storageKey = 'gfh_thermal_instruments_v1';
  final _uuid = const Uuid();
  final _random = Random();

  void _sortEntries() =>
      entries.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  String _generateMatrixId(InputNotifier p) {
    final code = systemCode(p.pyrometricSystem);
    final numeric = (100 + _random.nextInt(900)).toString();
    const outcomes = ['MELT', 'SLUMP', 'HOLD', 'MATCH'];
    final outcome = outcomes[_random.nextInt(outcomes.length)];
    return 'GFH-$code-$numeric-$outcome';
  }

  Future<void> loadEntries() async {
    isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        entries = (jsonDecode(jsonString) as List<dynamic>)
            .map((item) => ThermalInstrumentModel.fromJson(item))
            .toList();
        _sortEntries();
      }
    } catch (e) {
      debugPrint('Error loading thermal instruments: $e');
      entries = [];
    } finally {
      isLoading = false;
      stateVersion++;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  ThermalInstrumentModel _fromInput(
    WidgetRef ref, {
    ThermalInstrumentModel? existing,
  }) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    return ThermalInstrumentModel(
      id: existing?.id ?? _uuid.v4(),
      thermalConeMatrixId:
          existing?.thermalConeMatrixId ?? _generateMatrixId(p),
      pyrometricSystem: p.pyrometricSystem,
      coneMineralFormulation: p.coneMineralFormulation,
      deformationTemperatureTarget: p.deformationTemperatureTarget,
      filamentLampResistance: p.filamentLampResistance,
      filterGlassDensity: p.filterGlassDensity,
      wedgwoodExpansionCoefficient: p.wedgwoodExpansionCoefficient,
      slagColorIndex: p.slagColorIndex,
      sightTubeThreadPitch: p.sightTubeThreadPitch,
      smeltingHearthComplex: p.smeltingHearthComplex,
      deformationStatus: p.deformationStatus,
      era: p.era,
      notes: p.notes,
      photoPath: imgProv.resultImage.isNotEmpty
          ? imgProv.resultImage
          : (existing?.photoPath ?? p.photoPath),
      tags: List<String>.from(p.tags),
      dateAdded: existing?.dateAdded ?? DateTime.now(),
    );
  }

  void addEntry(WidgetRef ref) {
    entries = [_fromInput(ref), ...entries];
    _sortEntries();
    _save();
    stateVersion++;
    notifyListeners();
  }

  void editEntry(WidgetRef ref, int index) {
    final newList = List<ThermalInstrumentModel>.from(entries);
    newList[index] = _fromInput(ref, existing: entries[index]);
    entries = newList;
    _sortEntries();
    _save();
    stateVersion++;
    notifyListeners();
  }

  void deleteEntry(int index) {
    final newList = List<ThermalInstrumentModel>.from(entries)..removeAt(index);
    entries = newList;
    _save();
    stateVersion++;
    notifyListeners();
  }

  void fillInput(WidgetRef ref, int index) {
    final p = ref.read(inputProvider);
    final imgProv = ref.read(imageProvider);
    final entry = entries[index];
    p.thermalConeMatrixId = entry.thermalConeMatrixId;
    p.pyrometricSystem = entry.pyrometricSystem;
    p.coneMineralFormulation = entry.coneMineralFormulation;
    p.deformationTemperatureTarget = entry.deformationTemperatureTarget;
    p.filamentLampResistance = entry.filamentLampResistance;
    p.filterGlassDensity = entry.filterGlassDensity;
    p.wedgwoodExpansionCoefficient = entry.wedgwoodExpansionCoefficient;
    p.slagColorIndex = entry.slagColorIndex;
    p.sightTubeThreadPitch = entry.sightTubeThreadPitch;
    p.smeltingHearthComplex = entry.smeltingHearthComplex;
    p.deformationStatus = entry.deformationStatus;
    p.era = entry.era;
    p.notes = entry.notes;
    p.photoPath = entry.photoPath;
    p.tags = List<String>.from(entry.tags);
    p.dateAdded = entry.dateAdded;
    imgProv.resultImage = entry.photoPath;
    notifyListeners();
  }
}

final projectProvider = ChangeNotifierProvider<ProjectNotifier>(
  (ref) => ProjectNotifier(),
);
