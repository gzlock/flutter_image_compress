import 'dart:async';

import 'package:dynamic_parallel_queue/dynamic_parallel_queue.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

final _style = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w200,
);

class ProcessingToastWidget extends StatelessWidget {
  final Widget child;

  const ProcessingToastWidget({
    super.key,
    required this.child,
  });

  static ToastFuture showQueue(String title, Queue queue) {
    final max = queue.pending;
    final RxInt pending = RxInt(queue.pending);
    final Timer timer = Timer.periodic(Duration(milliseconds: 500), (_) {
      pending.value = queue.pending;
    });
    return showToastWidget(
      ProcessingToastWidget(
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(
                title,
                style: _style,
              ),
              SizedBox(height: 10),
              Text('进度 ${((1 - pending.value / max) * 100).toInt()}%'),
            ],
          ))),
      handleTouch: true,
      duration: Duration.zero,
      onDismiss: () => timer.cancel(),
    );
  }

  static ToastFuture showText(String text) {
    return showToastWidget(
      ProcessingToastWidget(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(text, style: _style),
          ],
        ),
      ),
      handleTouch: true,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(left: 10, right: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        constraints: BoxConstraints(
          minWidth: 200,
          maxWidth: 300,
          maxHeight: 300,
        ),
        padding: EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
