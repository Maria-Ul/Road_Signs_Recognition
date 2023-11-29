import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rsr_mobile/src/blocs/camera_bloc/camera_bloc.dart';
import 'package:rsr_mobile/src/blocs/permissions_bloc/permissions_bloc.dart';
import 'package:rsr_mobile/src/ui_kit/ui_colors.dart';
import 'package:rsr_mobile/src/widgets/detector_widget.dart';

/// To be used in applications as single source of truth
/// Outer accessible Widget which wraps all BLoCs and UI
class PermissionHandlerWidget extends StatefulWidget {
  const PermissionHandlerWidget({super.key});

  @override
  State<PermissionHandlerWidget> createState() => _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  PermissionsBloc permissionsBloc = PermissionsBloc();

  @override
  Widget build(BuildContext context) => BlocProvider.value(
        value: CameraBloc(),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: BlocBuilder<PermissionsBloc, PermissionsState>(
                  bloc: permissionsBloc,
                  builder: (_, permissionsBlocState) {
                    if (permissionsBloc.state is! PermissionsGrantedState) {
                      return Center(
                        child: TextButton(
                          style: TextButton.styleFrom(foregroundColor: UIColors.primary),
                          onPressed: () => permissionsBloc.add(CheckPermissionsEvent()),
                          child: const Text('GRAND PERMISSIONS'),
                        ),
                      );
                    }
                    return const DetectorWidget();
                  }),
            ),
          ],
        ),
      );
}
