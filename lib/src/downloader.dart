// ignore_for_file: unnecessary_string_interpolations

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:collection/collection.dart';
import 'dart:io' as platforms;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'download_request.dart';
import 'download_status.dart';
import 'download_task.dart';
import 'package:http/http.dart' as http;

import 'notifications/initializations.dart';
    Future<String> getImageBytes(String url) async {
    final supportDir = await getApplicationSupportDirectory();
    final cl = http.Client();
    final resp = await cl.get(Uri.parse(url));
    final bytes = resp.bodyBytes;
    final imageFile =
        File("${supportDir.path}/${DateTime.now().millisecond}.png");
    await imageFile.create();
    await imageFile.writeAsBytes(bytes);
    return imageFile.path;
  }
String fixPath(String originalPath) {
  return originalPath.replaceAll(r'\', '/');
}
class DownloadManager {
  
static String theadTf = "Notification";

  void showWithSmallImage(String thead,tbody,saveDir) async {
     
    const String url =
        "https://cdn-icons-png.flaticon.com/512/9496/9496502.png";

    final imageDir = await getImageBytes(url);

    NotificationMessage message = NotificationMessage.fromPluginTemplate(
       "Download Files",tbody,"" ,
        image: imageDir,
        launch: "${fixPath(saveDir)}"); // Changed to open the download directory
    _winNotifyPlugin.showNotificationPluginTemplate(message);
  }
  final _winNotifyPlugin = WindowsNotification(
      applicationId: DownloadManager.theadTf);
  final Map<String, DownloadTask> _cache = <String, DownloadTask>{};
  final Queue<DownloadRequest> _queue = Queue();
  var dio = Dio();
  static const partialExtension = ".partial";
  static const tempExtension = ".temp";

  // var tasks = StreamController<DownloadTask>();

  int maxConcurrentTasks = 2;
  int runningTasks = 0;


  static final DownloadManager _dm = new DownloadManager._internal();

  DownloadManager._internal();

  factory DownloadManager( {int? maxConcurrentTasks}) {
    if (maxConcurrentTasks != null) {
      _dm.maxConcurrentTasks = maxConcurrentTasks;
    }
    return _dm;
  }

  void Function(int, int) createCallback(url, int partialFileLength) =>
      (int received, int total) {
        getDownload(url)?.progress.value =
            (received + partialFileLength) / (total + partialFileLength);

        if (total == -1) {}
      };

  Future<void> download(String url,
   String savePath,
    cancelToken,
  String thead, 
  String tbody,
      {forceDownload = false}) async {
    
    late String partialFilePath;
    late File partialFile;
    try {
      var task = getDownload(url);

      if (task == null || task.status.value == DownloadStatus.canceled) {
        return;
      }
      setStatus(task, DownloadStatus.downloading);

      if (kDebugMode) {
        print(url);
      }
      var file = File(savePath.toString());
      partialFilePath = savePath + partialExtension;
      partialFile = File(partialFilePath);

      var fileExist = await file.exists();
      var partialFileExist = await partialFile.exists();

      if (fileExist) {
        int fileIndex = 1;
        String newFilePath;
        String baseFilePath = savePath.substring(0, savePath.lastIndexOf('.'));
        String fileExtension = savePath.substring(savePath.lastIndexOf('.'));
        do {
          newFilePath = '$baseFilePath($fileIndex)$fileExtension';
          fileIndex++;
        } while (await File(newFilePath).exists());
        if (kDebugMode) {
          print("File Exists, saving as $newFilePath");
        }
        await File(savePath).copy(newFilePath);
         if(platforms.Platform.isWindows || platforms.Platform.isMacOS){
showWithSmallImage(thead,tbody,savePath);
          }else{
        NotificationUtils().createCustomNotificationWithActionButtons(
      title: thead,
      body: tbody,
      payload: "no",
    );
          }
        setStatus(task, DownloadStatus.completed);
      } else if (partialFileExist) {
        if (kDebugMode) {
          print("Partial File Exists");
        }
        var partialFileLength = await partialFile.length();

        var response = await dio.download(url, partialFilePath + tempExtension,
            onReceiveProgress: createCallback(url, partialFileLength),
            options: Options(
              headers: {HttpHeaders.rangeHeader: 'bytes=$partialFileLength-'},
            ),
            cancelToken: cancelToken,
            deleteOnError: true);

        if (response.statusCode == HttpStatus.partialContent) {
          var ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
          // ignore: no_leading_underscores_for_local_identifiers
          var f = File(partialFilePath + tempExtension);
          await ioSink.addStream(f.openRead());
          await f.delete();
          await ioSink.close();
          await partialFile.rename(savePath);

          setStatus(task, DownloadStatus.completed);
        }
      } else {
        var response = await dio.download(url, partialFilePath,
            onReceiveProgress: createCallback(url, 0),
            cancelToken: cancelToken,
            deleteOnError: false);

        if (response.statusCode == HttpStatus.ok) {
          
          await partialFile.rename(savePath);
          if (kDebugMode) {
            print(fixPath(savePath));
          }
          if(platforms.Platform.isWindows || platforms.Platform.isMacOS){
showWithSmallImage(thead,tbody,savePath);
          }else{
         if (kDebugMode) {
           print("object")   ;
         }
          }
           
          setStatus(task, DownloadStatus.completed);

          
        }
      }
    } catch (e) {
      var task = getDownload(url)!;
      if (task.status.value != DownloadStatus.canceled &&
          task.status.value != DownloadStatus.paused) {
        setStatus(task, DownloadStatus.failed);
        runningTasks--;

        if (_queue.isNotEmpty) {
          _startExecution();
        }
        rethrow;
      } else if (task.status.value == DownloadStatus.paused) {
        final ioSink = partialFile.openWrite(mode: FileMode.writeOnlyAppend);
        final f = File(partialFilePath + tempExtension);
        if (await f.exists()) {
          await ioSink.addStream(f.openRead());
        }
        await ioSink.close();
      }
    }

    runningTasks--;

    if (_queue.isNotEmpty) {
      _startExecution();
    }
  }

  void disposeNotifiers(DownloadTask task) {
    // task.status.dispose();
    // task.progress.dispose();
  }

  void setStatus(DownloadTask? task, DownloadStatus status) {
    if (task != null) {
      task.status.value = status;

      // tasks.add(task);
      if (status.isCompleted) {
        disposeNotifiers(task);
      }
    }
  }


  Future<DownloadTask?> addDownload(String url, String savedDir,thead,tbody) async {
    if (url.isNotEmpty) {
      if (savedDir.isEmpty) {
        savedDir = ".";
      }

      var isDirectory = await Directory(savedDir).exists();
      var downloadFilename = isDirectory
          ? savedDir + Platform.pathSeparator + getFileNameFromUrl(url)
          : savedDir;

      return _addDownloadRequest(DownloadRequest(url, downloadFilename,thead,tbody));
    }
  }

  Future<DownloadTask> _addDownloadRequest(
    DownloadRequest downloadRequest,
  
  ) async {
    if (_cache[downloadRequest.url] != null) {
      if (!_cache[downloadRequest.url]!.status.value.isCompleted &&
          _cache[downloadRequest.url]!.request == downloadRequest) {
        // Do nothing
        return _cache[downloadRequest.url]!;
      } else {
        _queue.remove(_cache[downloadRequest.url]);
      }
    }

    _queue.add(DownloadRequest(downloadRequest.url, downloadRequest.path,downloadRequest.thead,downloadRequest.tbody));
    var task = DownloadTask(_queue.last);

    _cache[downloadRequest.url] = task;

    _startExecution();

    return task;
  }

  Future<void> pauseDownload(String url) async {
    if (kDebugMode) {
      print("Pause Download");
    }
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.paused);
    task.request.cancelToken.cancel();

    _queue.remove(task.request);
  }

  Future<void> cancelDownload(String url) async {
    if (kDebugMode) {
      print("Cancel Download");
    }
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.canceled);
    _queue.remove(task.request);
    task.request.cancelToken.cancel();
  }

  Future<void> resumeDownload(String url) async {
    if (kDebugMode) {
      print("Resume Download");
    }
    var task = getDownload(url)!;
    setStatus(task, DownloadStatus.downloading);
    task.request.cancelToken = CancelToken();
    _queue.add(task.request);

    _startExecution();
  }

  Future<void> removeDownload(String url) async {
    cancelDownload(url);
    _cache.remove(url);
  }

  // Do not immediately call getDownload After addDownload, rather use the returned DownloadTask from addDownload
  DownloadTask? getDownload(String url) {
    return _cache[url];
  }

  Future<DownloadStatus> whenDownloadComplete(String url,
      {Duration timeout = const Duration(hours: 2)}) async {
    DownloadTask? task = getDownload(url);

    if (task != null) {
      return task.whenDownloadComplete(timeout: timeout);
    } else {
      return Future.error("Not found");
    }
  }

  List<DownloadTask> getAllDownloads() {
    return _cache.values.toList();
  }

  // Batch Download Mechanism
  Future<void> addBatchDownloads(List<String> urls, String savedDir,thead,tbody) async {
    for (var url in urls) {
      addDownload(url, savedDir,thead,tbody);
    }
  }

  List<DownloadTask?> getBatchDownloads(List<String> urls) {
    return urls.map((e) => _cache[e]).toList();
  }

  Future<void> pauseBatchDownloads(List<String> urls) async {
    for (var element in urls) {
      pauseDownload(element);
    }
  }

  Future<void> cancelBatchDownloads(List<String> urls) async {
    for (var element in urls) {
      cancelDownload(element);
    }
  }

  Future<void> resumeBatchDownloads(List<String> urls) async {
    for (var element in urls) {
      resumeDownload(element);
    }
  }

  ValueNotifier<double> getBatchDownloadProgress(List<String> urls) {
    ValueNotifier<double> progress = ValueNotifier(0);
    var total = urls.length;

    if (total == 0) {
      return progress;
    }

    if (total == 1) {
      return getDownload(urls.first)?.progress ?? progress;
    }

    var progressMap = <String, double>{};

    for (var url in urls) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        progressMap[url] = 0.0;

        if (task.status.value.isCompleted) {
          progressMap[url] = 1.0;
          progress.value = progressMap.values.sum / total;
        }

        // ignore: prefer_typing_uninitialized_variables
        var progressListener;
        progressListener = () {
          progressMap[url] = task.progress.value;
          progress.value = progressMap.values.sum / total;
        };

        task.progress.addListener(progressListener);

        // ignore: prefer_typing_uninitialized_variables
        var listener;
        listener = () {
          if (task.status.value.isCompleted) {
            progressMap[url] = 1.0;
            progress.value = progressMap.values.sum / total;
            task.status.removeListener(listener);
            task.progress.removeListener(progressListener);
          }
        };

        task.status.addListener(listener);
      } else {
        total--;
      }
    }

    return progress;
  }

  Future<List<DownloadTask?>?> whenBatchDownloadsComplete(List<String> urls,
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<List<DownloadTask?>?>();

    var completed = 0;
    var total = urls.length;

    for (var url in urls) {
      DownloadTask? task = getDownload(url);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          if (completed == total) {
            completer.complete(getBatchDownloads(urls));
          }
        }

        // ignore: prefer_typing_uninitialized_variables
        var listener;
        listener = () {
          if (task.status.value.isCompleted) {
            completed++;

            if (completed == total) {
              completer.complete(getBatchDownloads(urls));
              task.status.removeListener(listener);
            }
          }
        };

        task.status.addListener(listener);
      } else {
        total--;

        if (total == 0) {
          completer.complete(null);
        }
      }
    }

    return completer.future.timeout(timeout);
  }

  void _startExecution() async {
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      if (kDebugMode) {
        print('Concurrent workers: $runningTasks');
      }
      var currentRequest = _queue.removeFirst();

      download(
          currentRequest.url, currentRequest.path, currentRequest.cancelToken,currentRequest.thead,currentRequest.tbody);

      // ignore: prefer_const_constructors
      await Future.delayed(Duration(milliseconds: 500), null);
    }
  }

  /// This function is used for get file name with extension from url
  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }
}
