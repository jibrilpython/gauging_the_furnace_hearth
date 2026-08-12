import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';

class InputNotifier extends ChangeNotifier {
  String _thermalConeMatrixId = '';
  PyrometricSystem _pyrometricSystem = PyrometricSystem.segerCone;
  ConeMineralFormulation _coneMineralFormulation =
      ConeMineralFormulation.kaolinFeldsparQuartz;
  String _deformationTemperatureTarget = '';
  String _filamentLampResistance = '';
  String _filterGlassDensity = '';
  String _wedgwoodExpansionCoefficient = '';
  SlagColorIndex _slagColorIndex = SlagColorIndex.brightCherry;
  SightTubeThreadPitch _sightTubeThreadPitch = SightTubeThreadPitch.bspHalf;
  String _smeltingHearthComplex = '';
  DeformationModelStatus _deformationStatus =
      DeformationModelStatus.requiresMeasurement;
  String _era = '';
  String _notes = '';
  String _photoPath = '';
  List<String> _tags = [];
  DateTime _dateAdded = DateTime.now();

  String get thermalConeMatrixId => _thermalConeMatrixId;
  PyrometricSystem get pyrometricSystem => _pyrometricSystem;
  ConeMineralFormulation get coneMineralFormulation => _coneMineralFormulation;
  String get deformationTemperatureTarget => _deformationTemperatureTarget;
  String get filamentLampResistance => _filamentLampResistance;
  String get filterGlassDensity => _filterGlassDensity;
  String get wedgwoodExpansionCoefficient => _wedgwoodExpansionCoefficient;
  SlagColorIndex get slagColorIndex => _slagColorIndex;
  SightTubeThreadPitch get sightTubeThreadPitch => _sightTubeThreadPitch;
  String get smeltingHearthComplex => _smeltingHearthComplex;
  DeformationModelStatus get deformationStatus => _deformationStatus;
  String get era => _era;
  String get notes => _notes;
  String get photoPath => _photoPath;
  List<String> get tags => _tags;
  DateTime get dateAdded => _dateAdded;

  set thermalConeMatrixId(String v) {
    _thermalConeMatrixId = v;
    notifyListeners();
  }

  set pyrometricSystem(PyrometricSystem v) {
    _pyrometricSystem = v;
    notifyListeners();
  }

  set coneMineralFormulation(ConeMineralFormulation v) {
    _coneMineralFormulation = v;
    notifyListeners();
  }

  set deformationTemperatureTarget(String v) {
    _deformationTemperatureTarget = v;
    notifyListeners();
  }

  set filamentLampResistance(String v) {
    _filamentLampResistance = v;
    notifyListeners();
  }

  set filterGlassDensity(String v) {
    _filterGlassDensity = v;
    notifyListeners();
  }

  set wedgwoodExpansionCoefficient(String v) {
    _wedgwoodExpansionCoefficient = v;
    notifyListeners();
  }

  set slagColorIndex(SlagColorIndex v) {
    _slagColorIndex = v;
    notifyListeners();
  }

  set sightTubeThreadPitch(SightTubeThreadPitch v) {
    _sightTubeThreadPitch = v;
    notifyListeners();
  }

  set smeltingHearthComplex(String v) {
    _smeltingHearthComplex = v;
    notifyListeners();
  }

  set deformationStatus(DeformationModelStatus v) {
    _deformationStatus = v;
    notifyListeners();
  }

  set era(String v) {
    _era = v;
    notifyListeners();
  }

  set notes(String v) {
    _notes = v;
    notifyListeners();
  }

  set photoPath(String v) {
    _photoPath = v;
    notifyListeners();
  }

  set tags(List<String> v) {
    _tags = v;
    notifyListeners();
  }

  set dateAdded(DateTime v) {
    _dateAdded = v;
    notifyListeners();
  }

  void clearAll() {
    _thermalConeMatrixId = '';
    _pyrometricSystem = PyrometricSystem.segerCone;
    _coneMineralFormulation = ConeMineralFormulation.kaolinFeldsparQuartz;
    _deformationTemperatureTarget = '';
    _filamentLampResistance = '';
    _filterGlassDensity = '';
    _wedgwoodExpansionCoefficient = '';
    _slagColorIndex = SlagColorIndex.brightCherry;
    _sightTubeThreadPitch = SightTubeThreadPitch.bspHalf;
    _smeltingHearthComplex = '';
    _deformationStatus = DeformationModelStatus.requiresMeasurement;
    _era = '';
    _notes = '';
    _photoPath = '';
    _tags = [];
    _dateAdded = DateTime.now();
    notifyListeners();
  }
}

final inputProvider = ChangeNotifierProvider<InputNotifier>(
  (ref) => InputNotifier(),
);
