import 'package:flutter/material.dart';
import 'package:rsr_mobile/src/models/detection_stats.dart';

class StatsWidget extends StatelessWidget {
  final DetectionStatsModel? stats;

  const StatsWidget(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return (stats != null)
        ? Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white.withAlpha(150),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatsRow('Conversion Time:', '${stats!.conversionTime} ms'),
                    StatsRow('Pre-Processing Time:', '${stats!.preProcessingTime} ms'),
                    StatsRow('Inference Time:', '${stats!.inferenceTime} ms'),
                    StatsRow('Total Prediction Time:', '${stats!.totalPredictionTime} ms'),
                    StatsRow('Frame Size:', '${stats!.frameWidth} X ${stats!.frameHeight}'),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}

class StatsRow extends StatelessWidget {
  final String left;
  final String right;

  const StatsRow(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(left), Text(right)],
        ),
      );
}
