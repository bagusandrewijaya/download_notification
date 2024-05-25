
import 'package:download_notification/src/notifications/initializations.dart';
import 'package:flutter/material.dart';
void main() {
  runApp(const MyApp());


  NotificationUtils().configuration();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ScreensOne()
    );
  }
}


class ScreensOne extends StatefulWidget {
  const ScreensOne({super.key});

  @override
  State<ScreensOne> createState() => _ScreensOneState();
}

class _ScreensOneState extends State<ScreensOne> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}


