class BoxModel {
  int classId;
  double xCenter;
  double yCenter;
  double width;
  double height;

  String get className {
    switch (classId) {
      case 0:
        return 'prohibitory';
      case 1:
        return 'danger';
      case 2:
        return 'mandatory';
      default:
        return 'other';
    }
  }

  BoxModel({
    required this.classId,
    required this.xCenter,
    required this.yCenter,
    required this.height,
    required this.width,
  });

  @override
  String toString() {
    return 'Class: $classId, xCenter: $xCenter, yCener: $yCenter, width: $width, height: $height';
  }
}
