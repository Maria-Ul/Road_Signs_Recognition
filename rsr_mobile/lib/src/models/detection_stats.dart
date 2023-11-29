class DetectionStatsModel {
  final int conversionTime;
  final int preProcessingTime;
  final int inferenceTime;
  final int totalPredictionTime;
  final int frameWidth;
  final int frameHeight;
  final List<String> classes;

  DetectionStatsModel({
    required this.conversionTime,
    required this.preProcessingTime,
    required this.inferenceTime,
    required this.totalPredictionTime,
    required this.frameWidth,
    required this.frameHeight,
    required this.classes,
  });

  @override
  String toString() {
    return 'DetectionStats{\n'
        '  Conversion Time: $conversionTime ms,\n'
        '  Pre-Processing Time: $preProcessingTime ms,\n'
        '  Inference Time: $inferenceTime ms,\n'
        '  Total Prediction Time: $totalPredictionTime ms,\n'
        '  Frame Size: $frameWidth X $frameHeight\n'
        '}';
  }
}
