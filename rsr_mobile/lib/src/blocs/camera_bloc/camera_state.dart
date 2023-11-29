part of 'camera_bloc.dart';

@immutable
abstract class CameraState extends Equatable {
  final CameraDescription? camera;

  const CameraState(this.camera);

  @override
  List<Object?> get props => [camera];
}

class CameraStateInitial extends CameraState {
  const CameraStateInitial() : super(null);
}

class CameraStateNotAvailable extends CameraState {
  const CameraStateNotAvailable() : super(null);
}

class CameraStateAvailable extends CameraState {
  const CameraStateAvailable(super.camera);
}
