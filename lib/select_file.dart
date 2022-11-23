import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

const XTypeGroup imageGroup = XTypeGroup(
  label: '图片',
  extensions: <String>['jpg', 'jpeg', 'png'],
);

class AddImage extends StatelessWidget {
  final void Function(List<ImageFile> files) listener;

  const AddImage({super.key, required this.listener});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: _select, child: Text('添加图片'));
  }

  void _select() async {
    final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[
      imageGroup,
    ]);
    listener(await Future.wait(files.map((f) async {
      final data = await f.readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(data);
      ui.FrameInfo frame = await codec.getNextFrame();
      return ImageFile(
        path: f.path,
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
