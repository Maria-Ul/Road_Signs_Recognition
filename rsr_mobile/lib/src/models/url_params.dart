import 'dart:isolate';

class UrlParamsModel {
  UrlParamsModel(this.path, this.sendPort);

  final String path;
  final SendPort sendPort;
}
