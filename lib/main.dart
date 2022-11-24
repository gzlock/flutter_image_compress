import 'dart:io';

import 'package:dynamic_parallel_queue/dynamic_parallel_queue.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'image.dart';
import 'select_file.dart';
import 'toast.dart';

late String tempPath;

final previewQueue = Queue(parallel: 2);
late final Queue outputQueue;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tempPath = (await getTemporaryDirectory()).path;
  debugPrint('临时路径 $tempPath');
  if (GetPlatform.isDesktop) {
    outputQueue = Queue(parallel: Platform.numberOfProcessors);
    await windowManager.ensureInitialized();
    final packageInfo = await PackageInfo.fromPlatform();
    final buildNumber =
        packageInfo.buildNumber.isEmpty ? '' : '+${packageInfo.buildNumber}';
    WindowOptions windowOptions = WindowOptions(
      title: '图片压缩 v${packageInfo.version}$buildNumber',
      size: Size(800, 600),
      minimumSize: Size(800, 600),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    outputQueue = Queue(parallel: 2);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: GetMaterialApp(
        locale: Locale("zh", "CN"),
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final RxDouble scale = 0.5.obs, quality = 0.5.obs;
  final RxMap<String, ImageFile> images = RxMap();

  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('压缩图片'),
        actions: [
          TextButton.icon(
            onPressed: _output,
            icon: Icon(Icons.compress, color: Colors.white),
            label: Text('压缩', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: CustomScrollView(slivers: [
        SliverList(
            delegate: SliverChildListDelegate([
          ListTile(
            title: Text('调整图片比例'),
            trailing:
                Obx(() => Text('当前比例：${scale.value.toStringAsPrecision(2)}')),
          ),
          ListTile(
            title: Obx(() => Slider(
                  value: scale.value,
                  onChanged: (val) => scale.value = val,
                  min: 0.1,
                  max: 5,
                )),
          ),
          ListTile(
            title: Text('调整图片质量'),
            trailing: Obx(() => Text('当前质量：${(quality.value * 100).toInt()}')),
          ),
          ListTile(
            title: Obx(() => Slider(
                  value: quality.value,
                  onChanged: (val) => quality.value = val,
                  min: 0.01,
                  max: 1,
                )),
          ),
        ])),
        SliverToBoxAdapter(
          child: ListTile(
            title: Text('图片预览'),
            trailing: AddImage(listener: (files) {
              for (var file in files) {
                if (images.containsKey(file.path)) continue;
                images[file.path] = file;
              }
            }),
          ),
        ),
        Obx(() => SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Obx(() => ImageWidget(
                      key: Key(images.values.elementAt(i).path),
                      quality: quality.value,
                      scale: scale.value,
                      input: images.values.elementAt(i),
                      removeListener: (file) => images.remove(file.path),
                    )),
                childCount: images.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: GetPlatform.isDesktop ? 3 : 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
            )),
      ]),
    );
  }

  void _output() async {
    if (images.isEmpty) return;
    outputQueue.clear();
    final String? directoryPath =
        await FilePicker.platform.getDirectoryPath(dialogTitle: '保存到哪里？');
    if (directoryPath == null) {
      return;
    }
    for (var file in images.values) {
      outputQueue.add(() async {
        final scaledWidth = (file.image.width * scale.value).toInt(),
            scaledHeight = (file.image.height * scale.value).toInt();
        final quality = (100 * this.quality.value).toInt();
        final compressed = await compress(
            bytes: file.rawBytes,
            width: scaledWidth,
            height: scaledHeight,
            quality: quality);
        final fileName = path.basenameWithoutExtension(file.path);
        final outputPath =
            path.join(directoryPath, '${fileName}_compressed.jpg');
        final outputFile = File(outputPath);
        outputFile.writeAsBytes(compressed);
      });
    }
    final toast = ProcessingToastWidget.showQueue('正在输出文件', outputQueue);
    await outputQueue.whenComplete();
    toast.dismiss();
    showToast('已完成全部输出');
  }
}
