import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:rsr_mobile/src/models/box.dart';
import 'package:rsr_mobile/src/models/detection_stats.dart';
import 'package:rsr_mobile/src/services/nms_service.dart';
import 'package:rsr_mobile/src/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

abstract class DetectorConfig {
  static const String modelPath = 'assets/models/yolo.tflite';
  static const int numClasses = 4;
  static const Size modelInputSize = Size(640, 640);
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.4;
  static const int numThreads = 2;
  static const int numAttributes = 4;
  static const int tensorSize = 8400;
  static int get totalOutputDimensions => numAttributes + numClasses;
}

enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}

class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}

class DetectorService {
  DetectorService._(this._isolate, this._interpreter);

  final Isolate _isolate;
  late final Interpreter _interpreter;
  late final SendPort _sendPort;

  bool _isReady = false;

  final StreamController<(List<BoxModel>, DetectionStatsModel)> resultsStream =
      StreamController<(List<BoxModel>, DetectionStatsModel)>();

  static Future<Interpreter> loadModel() async {
    final options = InterpreterOptions()..threads = DetectorConfig.numThreads;
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    return await Interpreter.fromAsset(
      DetectorConfig.modelPath,
      options: options,
    );
  }

  static Future<DetectorService> start() async {
    final ReceivePort receivePort = ReceivePort();
    final Isolate isolate = await Isolate.spawn(
      _DetectorServer._run,
      receivePort.sendPort,
    );
    final DetectorService result = DetectorService._(isolate, await loadModel());
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  void processFrame(CameraImage cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [rootIsolateToken, _interpreter.address]));
      case _Codes.ready:
        _isReady = true;
      case _Codes.busy:
        _isReady = false;
      case _Codes.result:
        _isReady = true;
        resultsStream.add(command.args?[0] as (List<BoxModel>, DetectionStatsModel));
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  void stop() {
    _isolate.kill();
  }
}

class _DetectorServer {
  _DetectorServer(this._sendPort);

  final SendPort _sendPort;
  Interpreter? _interpreter;

  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
        RootIsolateToken rootIsolateToken = command.args?[0] as RootIsolateToken;
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        _sendPort.send(const _Command(_Codes.ready));
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as CameraImage);
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  Future<void> _convertCameraImage(CameraImage cameraImage) async {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    var image = await ImageUtils.convertCameraImageToImage(cameraImage);
    if (image != null) {
      final results = await analyseImage(image, preConversionTime);
      _sendPort.send(_Command(_Codes.result, args: [results]));
    }
  }

  Future<(List<BoxModel>, DetectionStatsModel)> analyseImage(img.Image? image, int preConversionTime) async {
    var conversionElapsedTime = DateTime.now().millisecondsSinceEpoch - preConversionTime;
    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    final inputTensor = await _getInputTensor(image!);

    var preProcessElapsedTime = DateTime.now().millisecondsSinceEpoch - preProcessStart;
    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    final outputTensor = _getOutputTensor(
      totalOutputDimensions: DetectorConfig.totalOutputDimensions,
      tensorSize: DetectorConfig.tensorSize,
    );

    _interpreter?.run(inputTensor, outputTensor);

    var inferenceElapsedTime = DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    final detections = _getDetectionResults(outputTensor);

    var totalElapsedTime = DateTime.now().millisecondsSinceEpoch - preConversionTime;

    final stats = DetectionStatsModel(
      conversionTime: conversionElapsedTime,
      preProcessingTime: preProcessElapsedTime,
      inferenceTime: inferenceElapsedTime,
      totalPredictionTime: totalElapsedTime,
      frameWidth: image.width,
      frameHeight: image.height,
    );

    return (detections, stats);
  }

  Future<Uint8List> _getInputTensor(img.Image image) async {
    final (resizedImage, _, _) = await ImageUtils.resizeImage(
      image,
      width: DetectorConfig.modelInputSize.width.toInt(),
      height: DetectorConfig.modelInputSize.height.toInt(),
    );

    final inputTensor = ImageUtils.imageToByteListNormalized(
      resizedImage,
      width: DetectorConfig.modelInputSize.width.toInt(),
      height: DetectorConfig.modelInputSize.height.toInt(),
    );

    return inputTensor;
  }

  List<dynamic> _getOutputTensor({required int totalOutputDimensions, required int tensorSize}) {
    return List.generate(
      1,
      (index) => List.generate(
        totalOutputDimensions,
        (index) => List.filled(tensorSize, 0.0),
      ),
    );
  }

  List<BoxModel> _getDetectionResults(List<dynamic> outputTensor) {
    final (classes, boxes, _) = NMSService.performNMS(
      outputTensor[0],
      confidenceThreshold: DetectorConfig.confidenceThreshold,
      iouThreshold: DetectorConfig.iouThreshold,
      tensorSize: DetectorConfig.tensorSize,
      numAttributes: DetectorConfig.numAttributes,
      totalOutputDimensions: DetectorConfig.totalOutputDimensions,
    );
    List<BoxModel> detections = [];

    for (int i = 0; i < boxes.length; i++) {
      var box = boxes[i];
      var classId = classes[i];

      final detection = BoxModel(
        classId: classId,
        xCenter: box[0],
        yCenter: box[1],
        width: box[2],
        height: box[3],
      );

      detections.add(detection);
    }
    return detections;
  }
}
