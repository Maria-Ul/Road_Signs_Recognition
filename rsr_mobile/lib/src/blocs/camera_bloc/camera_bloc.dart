import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rsr_mobile/src/services/camera_service.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(const CameraStateInitial()) {
    on<CameraEventGet>(_onGet);
  }

  void _onGet(
    CameraEventGet event,
    Emitter<CameraState> emit,
  ) async {
    final camera = await CameraService.mainCamera();
    if (camera != null) {
      emit(CameraStateAvailable(camera));
    } else {
      emit(const CameraStateNotAvailable());
    }
  }
}
