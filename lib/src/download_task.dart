import 'dart:async';

import 'package:download_notification/src/download_request.dart';
import 'package:download_notification/src/download_status.dart';
import 'package:flutter/foundation.dart';

class DownloadTask {
  final DownloadRequest request;
  ValueNotifier<DownloadStatus> status = ValueNotifier(DownloadStatus.queued);
  ValueNotifier<double> progress = ValueNotifier(0);

  DownloadTask(
    this.request,
  );

  Future<DownloadStatus> whenDownloadComplete(
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<DownloadStatus>();

    if (status.value.isCompleted) {
      completer.complete(status.value);
    }

    // ignore: prefer_typing_uninitialized_variables
    var listener;
    listener = () {
      if (status.value.isCompleted) {
        completer.complete(status.value);
        status.removeListener(listener);
      }
    };

    status.addListener(listener);

    return completer.future.timeout(timeout);
  }
}
