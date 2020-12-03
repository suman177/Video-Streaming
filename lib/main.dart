import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'apis/encoding_provider.dart';
import 'apis/firebase_provider.dart';
import 'package:path/path.dart' as p;
import 'models/video_info.dart';
import 'widgets/player.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Sharing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Video Sharing'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  double _progress = 0.0;
  bool _canceled = false;
  int _videoDuration = 0;
  String _processPhase = "";


  @override
  void initState() {
    //
    EncodingProvider.enableStatisticsCallback((int time,
        int size,
        double bitrate,
        double speed,
        int videoFrameNumber,
        double videoQuality,
        double videoFps) {
      
      if (_canceled) return;

      setState(() {
        _progress = time / _videoDuration;
      });
    });

    super.initState();
  }

  //Widget to show Progress bar.
  _getProgressBar() {
    return Container(
      padding: EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 30.0),
            child: Text(_processPhase),
          ),
          LinearProgressIndicator(
            value: _progress,
          ),
        ],
      ),
    );
  }

  void _onUploadProgress(event) {
    if(event.type == StorageTaskEventType.progress) {
      final double progess = event.snapshot.byteTransferred / event.snapshot.totalByteCOunt
    }
  }
  //This method takes filepath foldreName as paramater and upload the file to the server
  //It will make a StorageReference on the server and handle live events and so on.
  Future<String> _uploadFile(filepath, folderName) async {
    final file = new File(filepath);
    final basename = p.basename(filepath);

    final StorageReference ref =
        FirebaseStorage.instance.ref().child(folderName).child(basename);
    StorageUploadTask uploadTask = ref.putFile(file);
    uploadTask.events.listen((_onUploadProgress));
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String videoUrl = await taskSnapshot.ref.getDownloadURL();

    return videoUrl;
  }

  //This method fixes the HLS file. '.ts' and '.m3u8' files are edited here to point to correct location which is cloud 
  //after we upload the video.
  void _updatePlaylistUrls(File file, String videoName) {
    final lines = file.readAsLinesSync();
    var updatedLines =List<String>();

    for(final String line in lines) {
      var updatedLine = line;
      if(line.contains('.ts') || line.contains('.m3u8')){
          updatedLine = '$videoName%2F$line?alt=media';
      }
      updatedLines.add(updatedLine);
    }

    final updatedContents = updatedLines.reduce((value, element)=> value + '\n' + element);

    file.writeAsStringSync(updatedContents);
  }

  Future<String> _uploadHLSFiles(dirPath, videoName) async {
    
    final videosDir = Directory(dirPath);

    var playlistUrl = '';
    
    final files = videosDir.listSync();
    int i =1;
    for (FileSystemEntity file in files) {
      final fileName = p.basename(file.path);
      final fileExtension = getFileExtension(fileName);

    }

  }

  //This method gives the extension of file to verify weather to upload or not
  //example will return .m3u8 if it is m3u8 file.
  String getFileExtension(String fileName) {
    final exploded =fileName.split('.');
    return exploded[exploded.length - 1];
  }
}
