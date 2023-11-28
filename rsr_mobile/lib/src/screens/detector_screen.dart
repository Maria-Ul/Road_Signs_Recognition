import 'package:flutter/material.dart';
import 'package:rsr_mobile/src/ui_kit/ui_colors.dart';
import 'package:rsr_mobile/src/widgets/permissions_handler_widget.dart';

class DetectorScreen extends StatelessWidget {
  const DetectorScreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: UIColors.background,
        child: Scaffold(
          backgroundColor: UIColors.background,
          body: const PermissionHandlerWidget(),
        ),
      );
}
