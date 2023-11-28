import 'dart:io';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

part 'permissions_event.dart';
part 'permissions_state.dart';

/// Permissions Bloc
class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  PermissionsBloc() : super(const PermissionsInitialState()) {
    on<CheckPermissionsEvent>(
      (event, emit) => _onCheckPermissions(event, emit),
      transformer: droppable(),
    );
    add(CheckPermissionsEvent());
  }

  void _onCheckPermissions(
    CheckPermissionsEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    // Handle camera and microphone permissions
    final Map<Permission, PermissionStatus> permissions = await [Permission.camera].request();

    // Add storage permission status to the map if SDK is below 33
    if (Platform.isAndroid) {
      permissions[Permission.microphone] = await Permission.microphone.request();
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;
      if (sdkInt < 33) {
        permissions[Permission.storage] = await Permission.storage.request();
      }
    }

    // Check the status of all permissions
    if (permissions.values.any((status) => status.isPermanentlyDenied)) {
      emit(const PermissionsPermDeniedState());
      openAppSettings(); // Guide user to app settings if any permission is permanently denied
    } else if (permissions.values.any((status) => status.isDenied)) {
      emit(const PermissionsDeniedState());
    } else {
      emit(const PermissionsGrantedState());
    }
  }
}
