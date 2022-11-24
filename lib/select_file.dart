import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AddImage extends StatelessWidget {
  final void Function(List<ImageFile> files) listener;

  const AddImage({super.key, required this.listener});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: _select, child: Text('添加图片'));
  }

  void _select() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result == null) return;

    listener(await Future.wait(result.files.map((f) async {
      final file = File(f.path!);
      final data = await file.readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(data);
      ui.FrameInfo frame = await codec.getNextFrame();
      return ImageFile(
        path: f.path!,
        rawBytes: data,
        image: frame.image,
      );
    })));
  }
}

class ImageFile {
  final String path;
  final Uint8List rawBytes;
  final ui.Image image;

  ImageFile({
    required this.path,
    required this.rawBytes,
    required this.image,
  });
}
