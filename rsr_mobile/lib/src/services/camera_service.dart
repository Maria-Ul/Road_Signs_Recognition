import 'package:camera/camera.dart';
import 'package:collection/collection.dart';

class CameraService {
  static Future<List<CameraDescription>> allCameras() async {
    List<CameraDescription> cameras = [];
    try {
      cameras = await availableCameras();
    } on CameraException {
      cameras = [];
    }
    return cameras;
  }

  static Future<CameraDescription?> mainCamera() async {
    final cameras = await allCameras();
    return cameras.firstOrNull;
  }
}
