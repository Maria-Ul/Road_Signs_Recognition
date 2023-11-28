import 'package:flutter/widgets.dart';
import 'package:rsr_mobile/src/models/box.dart';

class BoxUtils {
  static Rect calculateBoxPosition({
    required BoxModel box,
    required Size screenSize,
    required Size previewSize,
  }) {
    final scaledBox = _scaleBox(
      box: box,
      screenSize: screenSize,
    );

    final width = scaledBox.width;
    final height = scaledBox.height;
    final left = scaledBox.xCenter - width / 2;
    final top = scaledBox.yCenter - height / 2;

    return Rect.fromLTWH(left, top, width, height);
  }

  static BoxModel _scaleBox({
    required BoxModel box,
    required Size screenSize,
  }) {
    final screenH = screenSize.height;
    final screenW = screenSize.width;
    final resizeFactorW = screenW;
    final resizeFactorH = screenH;

    final scaledX = box.xCenter * resizeFactorW;
    final scaledY = box.yCenter * resizeFactorH;
    final scaledW = box.width * resizeFactorW;
    final scaledH = box.height * resizeFactorH;

    return BoxModel(
      classId: box.classId,
      xCenter: scaledX,
      height: scaledH,
      yCenter: scaledY,
      width: scaledW,
    );
  }
}
