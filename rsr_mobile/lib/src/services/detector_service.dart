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

enum DetectorModels {
  simple16,
  simple32,
  sweden16,
  sweden32,
}

class DetectorConfig {
  final String modelPath;
  final int numClasses;
  final Size modelInputSize = const Size(640, 640);
  final double confidenceThreshold = 0.5;
  final double iouThreshold = 0.4;
  final int numThreads = 2;
  final int numAttributes = 4;
  final int tensorSize = 8400;
  int get totalOutputDimensions => numAttributes + numClasses;

  final List<String> _classNames;

  DetectorConfig._(this.modelPath, this.numClasses, this._classNames);

  // Private constructors for different model types
  DetectorConfig._simple(String modelPath, DetectorModels model)
      : this._(
          modelPath,
          4,
          ['prohibitory', 'danger', 'mandatory', 'other'],
        );

  DetectorConfig._sweden(String modelPath, DetectorModels model)
      : this._(
          modelPath,
          20,
          [
            'INFORMATION_PRIORITY_ROAD',
            'MANDATORY_PASS_EITHER_SIDE',
            'MANDATORY_PASS_RIGHT_SIDE',
            'WARNING_GIVE_WAY',
            'PROHIBITORY_70_SIGN',
            'PROHIBITORY_90_SIGN',
            'OTHER_OTHER',
            'PROHIBITORY_80_SIGN',
            'PROHIBITORY_50_SIGN',
            'INFORMATION_PEDESTRIAN_CROSSING',
            'PROHIBITORY_60_SIGN',
            'PROHIBITORY_30_SIGN',
            'PROHIBITORY_NO_PARKING',
            'MANDATORY_PASS_LEFT_SIDE',
            'PROHIBITORY_110_SIGN',
            'PROHIBITORY_STOP',
            'PROHIBITORY_100_SIGN',
            'PROHIBITORY_NO_STOPPING_NO_STANDING',
            'UNREADABLE_URDBL',
            'PROHIBITORY_120_SIGN'
          ],
        );

  factory DetectorConfig(DetectorModels model) {
    switch (model) {
      case DetectorModels.simple16:
        return DetectorConfig._simple('assets/models/yolov8n_1128_01_ds3_ep50_float16.tflite', model);
      case DetectorModels.simple32:
        return DetectorConfig._simple('assets/models/yolov8n_1128_01_ds3_ep50_float32.tflite', model);
      case DetectorModels.sweden16:
        return DetectorConfig._sweden('assets/models/sweden_best_float16.tflite', model);
      case DetectorModels.sweden32:
        return DetectorConfig._sweden('assets/models/sweden_best_float32.tflite', model);
      default:
        throw ArgumentError('Invalid model type');
    }
  }

  String className(int classId) {
    return _classNames[classId];
  }
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

  static Future<Interpreter> loadModel(DetectorConfig config) async {
    final options = InterpreterOptions()..threads = config.numThreads;
    if (Platform.isAndroid) {
      options.addDelegate(XNNPackDelegate());
    }
    if (Platform.isIOS) {
      options.addDelegate(GpuDelegate());
    }

    return await Interpreter.fromAsset(
      config.modelPath,
      options: options,
    );
  }

  static Future<DetectorService> start(DetectorConfig config) async {
    final ReceivePort receivePort = ReceivePort();
    final Isolate isolate = await Isolate.spawn(
      (sendPort) => _DetectorServer._run(sendPort, config),
      receivePort.sendPort,
      errorsAreFatal: true,
    );
    final DetectorService result = DetectorService._(isolate, await loadModel(config));
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
  final DetectorConfig config;
  _DetectorServer(this._sendPort, this.config);

  final SendPort _sendPort;
  Interpreter? _interpreter;

  static void _run(SendPort sendPort, DetectorConfig config) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort, config);
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
      totalOutputDimensions: config.totalOutputDimensions,
      tensorSize: config.tensorSize,
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
      classes: detections.map((e) => e.className).toList(),
    );

    return (detections, stats);
  }

  Future<Uint8List> _getInputTensor(img.Image image) async {
    final (resizedImage, _, _) = await ImageUtils.resizeImage(
      image,
      width: config.modelInputSize.width.toInt(),
      height: config.modelInputSize.height.toInt(),
    );

    final inputTensor = ImageUtils.imageToByteListNormalized(
      resizedImage,
      width: config.modelInputSize.width.toInt(),
      height: config.modelInputSize.height.toInt(),
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
      confidenceThreshold: config.confidenceThreshold,
      iouThreshold: config.iouThreshold,
      tensorSize: config.tensorSize,
      numAttributes: config.numAttributes,
      totalOutputDimensions: config.totalOutputDimensions,
      enableNMS: true,
    );
    List<BoxModel> detections = [];

    for (int i = 0; i < boxes.length; i++) {
      var box = boxes[i];
      var classId = classes[i];

      final detection = BoxModel(
        className: config.className(classId),
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
