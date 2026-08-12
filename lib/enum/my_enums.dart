enum PyrometricSystem {
  segerCone('Seger cone'),
  ortonCone('Orton cone'),
  wedgwoodCylinder('Wedgwood cylinder'),
  disappearingFilament('Disappearing filament'),
  radiationPyrometer('Radiation pyrometer'),
  thermocoupleKit('Thermocouple kit');

  const PyrometricSystem(this.label);
  final String label;
}

enum ConeMineralFormulation {
  kaolinFeldsparQuartz('Kaolin-feldspar-quartz blend'),
  ironFluxSilicate('Iron-flux silicate'),
  aluminaSilicaBody('Alumina-silica body'),
  feldsparBallClay('Feldspar-ball clay mix'),
  porcelainSoftPaste('Porcelain soft-paste'),
  customClayBody('Custom clay body');

  const ConeMineralFormulation(this.label);
  final String label;
}

enum SlagColorIndex {
  dullRed('Dull red / ~700°C'),
  cherryRed('Cherry red / ~850°C'),
  brightCherry('Bright cherry orange / ~1000°C'),
  orangeYellow('Orange-yellow / ~1100°C'),
  whiteYellow('White-yellow / ~1200°C'),
  dazzlingWhite('Dazzling white / ~1400°C');

  const SlagColorIndex(this.label);
  final String label;
}

enum SightTubeThreadPitch {
  bspQuarter('BSP 1/4"'),
  bspHalf('BSP 1/2"'),
  nptThreeEighths('NPT 3/8"'),
  nptHalf('NPT 1/2"'),
  metricM20('Metric M20×1.5'),
  flangeMount('Flange mount / no thread');

  const SightTubeThreadPitch(this.label);
  final String label;
}

enum DeformationModelStatus {
  fullSlump('DFORM: FULL SLUMP'),
  partialSlump('DFORM: PARTIAL SLUMP'),
  upright('DFORM: UPRIGHT'),
  requiresMeasurement('DFORM: REQUIRES MEASUREMENT');

  const DeformationModelStatus(this.label);
  final String label;
}

enum KilnAtmosphere {
  oxidising('Oxidising'),
  reducing('Reducing'),
  neutral('Neutral');

  const KilnAtmosphere(this.label);
  final String label;
}
