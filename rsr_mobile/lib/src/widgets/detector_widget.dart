import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:rsr_mobile/src/blocs/camera_bloc/camera_bloc.dart';
import 'package:rsr_mobile/src/models/box.dart';
import 'package:rsr_mobile/src/models/detection_stats.dart';
import 'package:rsr_mobile/src/services/detector_service.dart';
import 'package:rsr_mobile/src/ui_kit/ui_colors.dart';
import 'package:rsr_mobile/src/ui_kit/ui_consts.dart';
import 'package:rsr_mobile/src/widgets/boxes_widget.dart';
import 'package:rsr_mobile/src/widgets/stats_widget.dart';

class DetectorWidget extends StatefulWidget {
  const DetectorWidget({super.key});

  @override
  State<DetectorWidget> createState() => _DetectorWidgetState();
}

class _DetectorWidgetState extends State<DetectorWidget> with WidgetsBindingObserver {
  CameraController? cameraController;
  DetectorService? _detectorService;
  StreamSubscription? _detectorSubscription;
  List<BoxModel> boxes = [];
  DetectionStatsModel? stats;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        _detectorService?.stop();
        _detectorSubscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        initializeCamera();
        initializeDetector();
        break;
      default:
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
    initializeDetector();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    _detectorService?.stop();
    _detectorSubscription?.cancel();
    super.dispose();
  }

  Future<void> initializeDetector() async {
    _detectorService = await DetectorService.start(DetectorConfig(DetectorModels.simple32));
    _detectorSubscription = _detectorService!.resultsStream.stream.listen((values) {
      setState(() {
        boxes = values.$1;
        stats = values.$2;
      });
    });
    setState(() {});
  }

  Future<void> initializeCamera() async {
    final cameraBloc = context.read<CameraBloc>();
    cameraBloc.add(CameraEventGet());
    await cameraBloc.stream.first;

    if (cameraBloc.state is CameraStateAvailable) {
      final camera = cameraBloc.state.camera!;
      cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController?.initialize();
      cameraController?.setFlashMode(FlashMode.off);
      await cameraController!.startImageStream((CameraImage cameraImage) async {
        _detectorService?.processFrame(cameraImage);
      });
      setState(() {});
    }
  }

  @override
  Future<void> didChangeMetrics() async {
    if (Platform.isIOS) {
      final orientation = await NativeDeviceOrientationCommunicator().orientation(useSensor: true);
      if (orientation == NativeDeviceOrientation.landscapeLeft) {
        cameraController?.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
      }
      if (orientation == NativeDeviceOrientation.landscapeRight) {
        cameraController?.lockCaptureOrientation(DeviceOrientation.landscapeRight);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (_, state) {
        if (state is CameraStateInitial) {
          return progressIndicator;
        }
        if (state is CameraStateNotAvailable) {
          return notAvailableText;
        }
        return cameraContent;
      },
    );
  }

  Widget get notAvailableText => const Center(child: Text('No available cameras found'));

  Widget get progressIndicator => Center(
        child: SizedBox(
          width: UISize.base12x,
          height: UISize.base12x,
          child: CircularProgressIndicator(color: UIColors.primary),
        ),
      );

  Widget get cameraContent {
    if (cameraController?.value.isInitialized != true) {
      return progressIndicator;
    } else {
      return Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100, // the actual width is not important here
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          BoxesWidget(
            boxes: boxes,
            previewSize: cameraController!.value.previewSize!,
          ),
          StatsWidget(stats),
        ],
      );
    }
  }
}
