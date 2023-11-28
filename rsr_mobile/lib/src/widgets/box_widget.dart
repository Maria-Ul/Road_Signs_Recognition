import 'package:flutter/material.dart';
import 'package:rsr_mobile/src/models/box.dart';
import 'package:rsr_mobile/src/ui_kit/ui_colors.dart';
import 'package:rsr_mobile/src/ui_kit/ui_consts.dart';
import 'package:rsr_mobile/src/utils/box_utils.dart';

class BoxWidget extends StatelessWidget {
  final BoxModel box;
  final Size previewSize;

  const BoxWidget({
    super.key,
    required this.box,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final positions = BoxUtils.calculateBoxPosition(
      box: box,
      screenSize: mediaQuery.size,
      previewSize: previewSize,
    );
    return Positioned(
      left: positions.left,
      top: positions.top,
      width: positions.width,
      height: positions.height,
      child: Container(
        padding: const EdgeInsets.all(UISize.base),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(UISize.base2x)),
          border: Border.all(
            color: UIColors.surface,
            width: UISize.base / 2,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Text(
            box.className,
            style: TextStyle(
              color: UIColors.surface,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
