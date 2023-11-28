import 'dart:math';

class NMSService {
  static (List<int>, List<List<double>>, List<double>) performNMS(
    List<List<double>> rawOutput, {
    required double confidenceThreshold,
    required double iouThreshold,
    required int tensorSize,
    required int numAttributes,
    required int totalOutputDimensions,
  }) {
    final transposedOutput = _transpose(rawOutput);

    List<int> bestClasses = [];
    List<double> bestScores = [];
    List<int> boxesToSave = [];

    for (int i = 0; i < tensorSize; i++) {
      double bestScore = 0;
      int bestCls = -1;
      for (int j = numAttributes; j < totalOutputDimensions; j++) {
        double clsScore = transposedOutput[i][j];
        if (clsScore > bestScore) {
          bestScore = clsScore;
          bestCls = j - numAttributes;
        }
      }
      if (bestScore > confidenceThreshold) {
        bestClasses.add(bestCls);
        bestScores.add(bestScore);
        boxesToSave.add(i);
      }
    }

    return _processResults(
      boxesToSave,
      transposedOutput,
      bestClasses,
      bestScores,
      iouThreshold,
    );
  }

  static List<List<double>> _transpose(List<List<double>> list) {
    List<List<double>> result = [];
    for (var i = 0; i < list[0].length; i++) {
      List<double> temp = [];
      for (var j = 0; j < list.length; j++) {
        temp.add(list[j][i]);
      }
      result.add(temp);
    }
    return result;
  }

  static (List<int>, List<List<double>>, List<double>) _processResults(
    List<int> boxesToSave,
    List<List<double>> transposedOutput,
    List<int> bestClasses,
    List<double> bestScores,
    double iouThreshold,
  ) {
    List<List<double>> candidateBoxes = boxesToSave.map((index) => transposedOutput[index]).toList();
    List<List<double>> finalBoxes = [];
    List<double> finalScores = [];
    List<int> finalClasses = [];

    while (candidateBoxes.isNotEmpty) {
      var bbox1xywh = candidateBoxes.removeAt(0);
      var bbox1xyxy = _xywh2xyxy(bbox1xywh);
      finalBoxes.add(bbox1xywh);
      finalScores.add(bestScores.removeAt(0));
      finalClasses.add(bestClasses.removeAt(0));

      candidateBoxes = candidateBoxes.where((bbox2xywh) {
        var bbox2xyxy = _xywh2xyxy(bbox2xywh);
        return _computeIou(bbox1xyxy, bbox2xyxy) <= iouThreshold;
      }).toList();
    }

    return (finalClasses, finalBoxes, finalScores);
  }

  /// Computes the intersection over union between two bounding boxes encoded with
  /// the xyxy format.
  static double _computeIou(List<double> bbox1, List<double> bbox2) {
    assert(bbox1[0] < bbox1[2]);
    assert(bbox1[1] < bbox1[3]);
    assert(bbox2[0] < bbox2[2]);
    assert(bbox2[1] < bbox2[3]);

    // Determine the coordinate of the intersection rectangle
    double xLeft = max(bbox1[0], bbox2[0]);
    double yTop = max(bbox1[1], bbox2[1]);
    double xRight = min(bbox1[2], bbox2[2]);
    double yBottom = min(bbox1[3], bbox2[3]);

    if (xRight < xLeft || yBottom < yTop) {
      return 0;
    }
    double intersectionArea = (xRight - xLeft) * (yBottom - yTop);
    double bbox1Area = (bbox1[2] - bbox1[0]) * (bbox1[3] - bbox1[1]);
    double bbox2Area = (bbox2[2] - bbox2[0]) * (bbox2[3] - bbox2[1]);

    double iou = intersectionArea / (bbox1Area + bbox2Area - intersectionArea);
    assert(iou >= 0 && iou <= 1);
    return iou;
  }

  static List<double> _xywh2xyxy(List<double> bbox) {
    double halfWidth = bbox[2] / 2;
    double halfHeight = bbox[3] / 2;
    return [
      bbox[0] - halfWidth,
      bbox[1] - halfHeight,
      bbox[0] + halfWidth,
      bbox[1] + halfHeight,
    ];
  }
}
