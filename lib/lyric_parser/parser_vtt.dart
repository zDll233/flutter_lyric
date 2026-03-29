import 'package:flutter_lyric/lyric_parser/lyrics_parse.dart';
import 'package:flutter_lyric/lyrics_log.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';

/// WebVTT 格式歌词解析器
class ParserVtt extends LyricsParse {
  /// 匹配时间轴行的正则 
  /// 例如: 00:00:01.000 --> 00:00:04.000 或 00:01.500 --> 00:03.000
  RegExp pattern = RegExp(r"(\d{2}:)?\d{2}:\d{2}.\d{3}\s+-->\s+(\d{2}:)?\d{2}:\d{2}.\d{3}");

  /// 提取开始时间的正则
  RegExp startTimePattern = RegExp(r"((\d{2}:)?\d{2}:\d{2}.\d{3})");

  ParserVtt(String lyric) : super(lyric);

  @override
  bool isOK() => lyric.startsWith("WEBVTT");

  @override
  List<LyricsLineModel> parseLines({bool isMain = true}) {
    // 统一换行符并分割
    var lines = lyric.replaceAll("\r\n", "\n").split("\n");
    if (lines.isEmpty) {
      LyricsLog.logD("未解析到 WebVTT 内容");
      return [];
    }

    List<LyricsLineModel> lineList = [];
    
    // 遍历行，WebVTT 通常是：时间行紧跟内容行
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      // 寻找匹配时间轴的行
      if (pattern.hasMatch(line)) {
        // 匹配到时间轴后，下一行通常就是歌词内容
        if (i + 1 < lines.length) {
          var realLyrics = lines[i + 1].trim();
          
          // 提取开始时间字符串
          var startTimeStr = startTimePattern.firstMatch(line)?.group(1);
          if (startTimeStr == null) continue;

          // 转为毫秒时间戳
          var ts = vttTimeToTS(startTimeStr);
          
          LyricsLog.logD("VTT匹配时间: $startTimeStr($ts) 内容: $realLyrics");

          var lineModel = LyricsLineModel()..startTime = ts;
          
          // 根据需求填入主歌词或副歌词
          if (isMain) {
            lineModel.mainText = realLyrics;
          } else {
            lineModel.extText = realLyrics;
          }
          
          lineList.add(lineModel);
          // 跳过内容行，继续寻找下一个时间轴
          i++; 
        }
      }
    }
    return lineList;
  }

  /// 将 VTT 时间字符串 (HH:mm:ss.SSS 或 mm:ss.SSS) 转为毫秒
  int? vttTimeToTS(String timeStr) {
    try {
      var parts = timeStr.split(':');
      double secondsWithMs;
      int minutes = 0;
      int hours = 0;

      if (parts.length == 3) {
        // HH:mm:ss.SSS
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        secondsWithMs = double.parse(parts[2]);
      } else if (parts.length == 2) {
        // mm:ss.SSS
        minutes = int.parse(parts[0]);
        secondsWithMs = double.parse(parts[1]);
      } else {
        return null;
      }

      int seconds = secondsWithMs.floor();
      int milliseconds = ((secondsWithMs - seconds) * 1000).round();

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      ).inMilliseconds;
    } catch (e) {
      LyricsLog.logW("VTT时间转换失败: $timeStr, error: $e");
      return null;
    }
  }
}