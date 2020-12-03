import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

//Server Less Encoding can be done here.
//Client will encode the video that is then transfered to server.
class EncodingProvider {
  static final FlutterFFmpeg _encoder = FlutterFFmpeg();
  static final FlutterFFprobe _probe = FlutterFFprobe();
  static final FlutterFFmpegConfig _config = FlutterFFmpegConfig();

  //Method used to get thumbnail for video. argument Variable contains detail
  //will take one frame from the video and return in String format;
  static Future<String> getThumb(videoPath, width, height) async {
    assert(File(videoPath).existsSync());

    final String outPath = '$videoPath.jpg';
    final arguments =
        '-y -i $videoPath -vframes 1 -an -s ${width}x$height -ss 1 $outPath';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);
    assert(File(outPath).existsSync());

    return outPath;
  }

  //This method is used to getMediaInformation.
  static Future<Map<dynamic, dynamic>> getMediaInformation(String path) async {
    assert(File(path).existsSync());
    return await _probe.getMediaInformation(path);
  }

  //This method is used to calculate Aspect Ratio so that it can be Shown in the phone or other device.
  static double getAspectRatio(Map<dynamic, dynamic> info) {
    final int width = info['streams'][0]['width'];
    final int height = info['streams'][0]['height'];
    final double aspect = height / width;
    return aspect;
  }

  //This method returns Duration of the video, this is useful when encoding the video.
  static int getDuration(Map<dynamic, dynamic> info) {
    return info['duration'];
  }

  //This method is used to encode the video into different formats
  //Here 2000k bitrate and 365k vitrate which will generate multiple fileSequence.ts file (video chunks)
  //each of varity of quality and one playlistVaraant.m3u8 (playlist) for each Stream
  //it will also generate master.m3u8 that lists all the playlistVariants.m3u8 file.
  static Future<String> encodeHLS(videoPath, outDirPath) async {
    assert(File(videoPath).existsSync());

    final arguments = '-y -i $videoPath' +
        '-preset ultrafast -g 48 -sc_thereashod 0' +
        '-map 0:0 -map 0:1 -map 0:0 -map 0:1' +
        '-c:v:0 libx264 -b:v:0 20000k' +
        '-c:v:0 libx264 -b:v:1 365k' +
        '-c:a copy' +
        '-var_stream_m,ap "v:0,a:0 v:1,a:1" ' +
        '-master_pl_name master.m3u8' +
        '-f hls -hls_time 6 -hls_list_size 0' +
        '-hls_segemtn_filename "$outDirPath/%v_fileSqeuence_%d.ts" ' +
        '$outDirPath/%v_playlistVariant.m3u8';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);

    return outDirPath;
  }

  //This method uses FFmpeg for client side video encoding.
  //This method returns essential variable needed to calculate time, size, bitrate, speed.
  static void enableStatisticsCallback(Function cb) {
    return _config.enableStatisticsCallback((time, size, bitrate, speed,
            videoFrameNumber, videoQuality, videoFps) =>
        cb);
  }

  //
}
