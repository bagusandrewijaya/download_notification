#✨DOWNLOAD_NOTIFICATION ✨
## Awesome Library For Notification Download Any Platform


![Alt Text](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExc2x1MWIydHE4ejRtcGJjbzF2b2F3bXlkMWY4Nm51c3lhN2IzY2V5cyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/tTHkthK2BUd33t8hUK/source.gif)
<br>
<img src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZnU5aTkxbXplbzk2ejdjbjBiZjZkdGY3Y3Brc3NuaGJnMW12c2o3ZyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/aVC6cYxc8hjoHKNSDY/giphy.gif" width="120" height="250" />

library that allows you to send notifications when the download process is complete on all platforms (possible)
This library is taken from several other code sources on pub.dev


## Installation
Easy To Use 

```dart
instal this library
download_notification: ^latest
```
- INITIAL LIBRARY NOTIFICATION ON YOUR MAIN
```dart
void main() {
   NotificationUtils().configuration();
  runApp( MyApp());
}
```
```dart
 var url4 =
      "https://go.microsoft.com/fwlink/?LinkID=521962";
  var savedDir = ""; 
  void downloadTask()async{
           await DownloadManager().addDownload(
            url4,
          "$savedDir/sampledata.xlsx",
          "APP NAME",
          "BODY NAME");
  }
```



## License

MIT


[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)


