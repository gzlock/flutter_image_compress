import 'dart:io';

import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'md5.dart';
import 'select_file.dart';

const Map<String, File> caches = {};

class PreviewImage extends StatelessWidget {
  final double quality;
  final double scale;
  final ImageFile input;
  final Rxn<File> preview = Rxn();
  final void Function(ImageFile file)? removeListener;

  PreviewImage({
    super.key,
    required this.quality,
    required this.scale,
    required this.input,
    this.removeListener,
  });

  @override
  Widget build(BuildContext context) {
    print('build ${input.path}');
    final width = input.image.width, height = input.image.height;
    final scaledWidth = (width * scale).toInt(),
        scaledHeight = (height * scale).toInt();
    final quality = (100 * this.quality).toInt();
    var previewSize = 0;
    previewQueue.add(() async {
      final List<int> resizedBytes = await compress(
        bytes: input.rawBytes,
        width: scaledWidth,
        height: scaledHeight,
        quality: quality,
      );
      final previewPath = path.join(tempPath, generateMd5(input.path));
      previewSize = resizedBytes.length;
      print('临时路径 $previewPath');
      final file = File(previewPath);
      await file.writeAsBytes(resizedBytes);
      preview.value = file;
    });
    return Stack(
      children: [
        Container(color: Colors.black),
        GestureDetector(
          child: Center(
              child: Image.memory(
            input.rawBytes,
            fit: BoxFit.cover,
          )),
          onTap: () {
            if (preview.value == null) {
              showToast('请等待生成预览');
            } else {
              launchUrl(Uri.file(preview.value!.path));
            }
          },
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Tooltip(
            message: '移除',
            child: GestureDetector(
              child: Icon(Icons.close, color: Colors.red),
              onTap: () => removeListener?.call(input),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.white.withOpacity(0.7),
            child: Obx(
              () => Text(
                  '原始：$width x $height, ${filesize(input.rawBytes.length)}\n'
                  '压缩：$scaledWidth x $scaledHeight, ${preview.value == null ? '生成中' : filesize(previewSize)}'),
            ),
          ),
        ),
      ],
    );
  }
}

Future<List<int>> compress({
  required List<int> bytes,
  required int width,
  required int height,
  required int quality,
}) async {
  final img.Image image = img.decodeImage(bytes)!;
  final img.Image resized = img.copyResize(
    image,
    width: width,
    height: height,
  );
  final List<int> resizedBytes = img.encodeJpg(resized, quality: quality);
  return resizedBytes;
}
