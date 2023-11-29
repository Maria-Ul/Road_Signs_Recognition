# rsr_mobile

The mobile application part of the "Road Signs Recognition" project.
The application can be run on Apple and Android smartphones and tablets.

## How to compile it?
1. [Install Flutter](https://docs.flutter.dev/get-started/install)
2. [Install FVM](https://fvm.app/docs/getting_started/installation/)
2. [Install Ultralytics](https://docs.ultralytics.com/quickstart/)
3. Export the YOLO model to tflite, e.g. `yolo export model=model_name.pt format=tflite`
4. Place the output models in the `assets/models`
