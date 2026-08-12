import 'package:gauging_the_furnace_hearth/enum/my_enums.dart';

class ThermalInstrumentModel {
  String id;
  String thermalConeMatrixId;
  PyrometricSystem pyrometricSystem;
  ConeMineralFormulation coneMineralFormulation;
  String deformationTemperatureTarget;
  String filamentLampResistance;
  String filterGlassDensity;
  String wedgwoodExpansionCoefficient;
  SlagColorIndex slagColorIndex;
  SightTubeThreadPitch sightTubeThreadPitch;
  String smeltingHearthComplex;
  DeformationModelStatus deformationStatus;
  String era;
  String notes;
  String photoPath;
  List<String> tags;
  DateTime dateAdded;

  ThermalInstrumentModel({
    required this.id,
    required this.thermalConeMatrixId,
    required this.pyrometricSystem,
    required this.coneMineralFormulation,
    required this.deformationTemperatureTarget,
    required this.filamentLampResistance,
    required this.filterGlassDensity,
    required this.wedgwoodExpansionCoefficient,
    required this.slagColorIndex,
    required this.sightTubeThreadPitch,
    required this.smeltingHearthComplex,
    required this.deformationStatus,
    required this.era,
    required this.notes,
    required this.photoPath,
    required this.tags,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'thermalConeMatrixId': thermalConeMatrixId,
        'pyrometricSystem': pyrometricSystem.name,
        'coneMineralFormulation': coneMineralFormulation.name,
        'deformationTemperatureTarget': deformationTemperatureTarget,
        'filamentLampResistance': filamentLampResistance,
        'filterGlassDensity': filterGlassDensity,
        'wedgwoodExpansionCoefficient': wedgwoodExpansionCoefficient,
        'slagColorIndex': slagColorIndex.name,
        'sightTubeThreadPitch': sightTubeThreadPitch.name,
        'smeltingHearthComplex': smeltingHearthComplex,
        'deformationStatus': deformationStatus.name,
        'era': era,
        'notes': notes,
        'photoPath': photoPath,
        'tags': tags,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory ThermalInstrumentModel.fromJson(Map<String, dynamic> json) {
    return ThermalInstrumentModel(
      id: json['id'] ?? '',
      thermalConeMatrixId: json['thermalConeMatrixId'] ?? '',
      pyrometricSystem:
          PyrometricSystem.values.asNameMap()[json['pyrometricSystem']] ??
              PyrometricSystem.segerCone,
      coneMineralFormulation: ConeMineralFormulation.values
              .asNameMap()[json['coneMineralFormulation']] ??
          ConeMineralFormulation.kaolinFeldsparQuartz,
      deformationTemperatureTarget: json['deformationTemperatureTarget'] ?? '',
      filamentLampResistance: json['filamentLampResistance'] ?? '',
      filterGlassDensity: json['filterGlassDensity'] ?? '',
      wedgwoodExpansionCoefficient: json['wedgwoodExpansionCoefficient'] ?? '',
      slagColorIndex:
          SlagColorIndex.values.asNameMap()[json['slagColorIndex']] ??
              SlagColorIndex.brightCherry,
      sightTubeThreadPitch: SightTubeThreadPitch.values
              .asNameMap()[json['sightTubeThreadPitch']] ??
          SightTubeThreadPitch.bspHalf,
      smeltingHearthComplex: json['smeltingHearthComplex'] ?? '',
      deformationStatus: DeformationModelStatus.values
              .asNameMap()[json['deformationStatus']] ??
          DeformationModelStatus.requiresMeasurement,
      era: json['era'] ?? '',
      notes: json['notes'] ?? '',
      photoPath: json['photoPath'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      dateAdded: DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
    );
  }
}
