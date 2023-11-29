class BoxModel {
  String className;
  double xCenter;
  double yCenter;
  double width;
  double height;

  BoxModel({
    required this.className,
    required this.xCenter,
    required this.yCenter,
    required this.height,
    required this.width,
  });

  @override
  String toString() {
    return 'Class: $className, xCenter: $xCenter, yCener: $yCenter, width: $width, height: $height';
  }
}
