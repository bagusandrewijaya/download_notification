// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dio/dio.dart';

class DownloadRequest {
  final String url;
  final String path;
  var cancelToken = CancelToken();
  var forceDownload = false;
String thead;
  String tbody;
  DownloadRequest(
    this.url,
    this.path,
    this.thead,
    this.tbody,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadRequest &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          path == other.path;

  @override
  int get hashCode => url.hashCode ^ path.hashCode;
}
