import 'dart:io';

import 'package:flutter/material.dart';
import 'package:download_notification/flutter_download_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const Sample(),
    );
  }
}

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample>{

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
         String? selectedCat;

         DateTime? selected;
 var url4 =
      "https://api.rsummi.co.id:1843/abc";
   var downloadManager = DownloadManager();
  var savedDir = ""; 
  void downloadTask()async{
           await DownloadManager().addDownload(
            url4,
          "$savedDir/sampledata.xlsx",
          "APP NAME",
          "BODY NAME"
                          );
  }

  @override
  void initState() {
   getDownloadsDirectory().then((value) => savedDir = value!.path);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
    
        child: ElevatedButton(onPressed: (){
downloadTask();
        }, child: Text("Downlaod")),
      ),
    );
  }
}