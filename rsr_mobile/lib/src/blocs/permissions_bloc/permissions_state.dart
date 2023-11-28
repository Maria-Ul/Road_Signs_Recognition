part of 'permissions_bloc.dart';

enum PermissionsStatus { initial, granted, denied, permanentlyDenied }

@immutable
abstract class PermissionsState extends Equatable {
  final PermissionsStatus status;

  const PermissionsState(this.status);

  @override
  List<Object> get props => [status];
}

class PermissionsInitialState extends PermissionsState {
  const PermissionsInitialState() : super(PermissionsStatus.initial);
}

class PermissionsGrantedState extends PermissionsState {
  const PermissionsGrantedState() : super(PermissionsStatus.granted);
}

class PermissionsDeniedState extends PermissionsState {
  const PermissionsDeniedState() : super(PermissionsStatus.denied);
}

class PermissionsPermDeniedState extends PermissionsState {
  const PermissionsPermDeniedState() : super(PermissionsStatus.permanentlyDenied);
}
