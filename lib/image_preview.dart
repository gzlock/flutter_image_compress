import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

class ImagePreview extends StatelessWidget {
  final double scale;
  final int quality, width, height;
  final Rx<Matrix4> matrix = Rx(Matrix4.identity());
  final File file;

  ImagePreview({
    super.key,
    required this.file,
    required this.scale,
    required this.quality,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('预览压缩后的图片'),
      ),
      body: MatrixGestureDetector(
        shouldRotate: false,
        onMatrixUpdate: (Matrix4 m, Matrix4 tm, Matrix4 sm, Matrix4 rm) {
          matrix.value = m;
        },
        child: Obx(() => Container(
              width: double.maxFinite,
              height: double.maxFinite,
              transform: matrix.value,
              child: Image.file(file),
            )),
      ),
      floatingActionButton: Container(
        padding: EdgeInsets.all(8),
        color: Colors.black.withOpacity(0.3),
        child: Text(
          '压缩后的数据：\n'
          '分辨率：$width x $height\n'
          '容量：${filesize(file.lengthSync())}',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
