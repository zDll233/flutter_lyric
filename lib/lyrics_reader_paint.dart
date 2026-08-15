import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_helper.dart';
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';
import 'package:flutter_lyric/lyrics_log.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';

///draw lyric reader
class LyricsReaderPaint extends ChangeNotifier implements CustomPainter {
  LyricsReaderModel? model;

  LyricUI lyricUI;

  LyricsReaderPaint(this.model, this.lyricUI);

  ///hover 行背景色 (null = 不显示 hover 效果)
  Color? hoverColor;

  ///hover 行左侧起始时间文本颜色 (null = 不显示)
  Color? hoverTimeColor;

  ///点击涟漪颜色 (null = 不显示涟漪)
  Color? rippleColor;

  ///hover 行背景透明度
  double hoverOpacity = 0.08;

  ///涟漪透明度 (扩散阶段)
  double rippleOpacity = 0.25;

  ///行框 (hover/涟漪裁剪) 圆角
  double cornerRadius = 8;

  ///左对齐时歌词行的行内左边距 (与行框左缘保持间距)
  double lineLeftPadding = 12;

  ///行框上下边距 (文字上下留白)
  double lineRectPadding = 12;

  int _hoverLineIndex = -1;

  ///鼠标悬停的歌词行, -1 表示无
  int get hoverLineIndex => _hoverLineIndex;

  set hoverLineIndex(int value) {
    if (_hoverLineIndex != value) {
      _hoverLineIndex = value;
      refresh();
    }
  }

  int _pressedLineIndex = -1;
  double _rippleProgress = 0;
  double _rippleFade = 0;
  Offset _pressedPoint = Offset.zero;

  int get pressedLineIndex => _pressedLineIndex;

  set pressedLineIndex(int value) {
    if (_pressedLineIndex != value) {
      _pressedLineIndex = value;
      refresh();
    }
  }

  double get rippleProgress => _rippleProgress;

  set rippleProgress(double value) {
    _rippleProgress = value;
    refresh();
  }

  ///涟漪透明度系数 (1 = 完全可见, 0 = 已淡出)
  double get rippleFade => _rippleFade;

  set rippleFade(double value) {
    _rippleFade = value;
    refresh();
  }

  Offset get pressedPoint => _pressedPoint;

  set pressedPoint(Offset value) {
    _pressedPoint = value;
    refresh();
  }

  ///高亮混合�? 
  var lightBlendPaint = Paint()
    ..blendMode = BlendMode.srcIn
    ..isAntiAlias = true;

  var playingIndex = 0;


  double _lyricOffset = 0;

  set lyricOffset(double offset) {
    if (checkOffset(offset)) {
      _lyricOffset = offset;
      refresh();
    }
  }

  double totalHeight = 0;

  var cachePlayingIndex = -1;

  clearCache() {
    cachePlayingIndex = -1;
    highlightWidth = 0;
  }

  ///check offset illegal
  ///true is OK
  ///false is illegal
  bool checkOffset(double? offset) {
    if (offset == null) return false;

    calculateTotalHeight();

    if (offset >= maxOffset && offset <= 0) {
      return true;
    } else {
      if (offset <= maxOffset && offset > _lyricOffset) {
        return true;
      }
    }
    LyricsLog.logD("越界取消偏移 可偏移：$maxOffset 目标偏移：$offset 当前：$_lyricOffset ");
    return false;
  }

  ///calculateTotalHeight
  void calculateTotalHeight() {
    ///缓存下，避免多余计算
    if (cachePlayingIndex != playingIndex) {
      cachePlayingIndex = playingIndex;
      var lyrics = model?.lyrics ?? [];
      double lastLineSpace = 0;
      //最大偏移量不包含最后一行
      if (lyrics.isNotEmpty) {
        lyrics = lyrics.sublist(0, lyrics.length - 1);
        lastLineSpace = LyricHelper.getLineSpaceHeight(lyrics.last, lyricUI,
            excludeInline: true);
      }
      totalHeight = -LyricHelper.getTotalHeight(lyrics, playingIndex, lyricUI) +
          (model?.firstCenterOffset(playingIndex, lyricUI) ?? 0) -
          (model?.lastCenterOffset(playingIndex, lyricUI) ?? 0) -
          lastLineSpace;
    }
  }

  double get baseOffset => lyricUI.halfSizeLimit()
      ? mSize.height * (0.5 - lyricUI.getPlayingLineBias())
      : 0;

  double get maxOffset {
    calculateTotalHeight();
    return baseOffset + totalHeight;
  }

  double get lyricOffset => _lyricOffset;

  //限制刷新频率
  int ts = DateTime.now().microsecond;

  refresh() {
    notifyListeners();
  }

  var _centerLyricIndex = 0;

  set centerLyricIndex(int value) {
    _centerLyricIndex = value;
    centerLyricIndexChangeCall?.call(value);
  }

  int get centerLyricIndex => _centerLyricIndex;

  Function(int)? centerLyricIndexChangeCall;

  Size mSize = Size.zero;

  ///给外部C位位置
  var centerY = 0.0;

  @override
  bool? hitTest(Offset position) => null;

  @override
  void paint(Canvas canvas, Size size) {
    //全局尺寸信息
    mSize = size;
    //溢出裁剪 (右侧留余量, 避免文字右缘抗锯齿被裁掉)
    canvas.clipRect(
        Rect.fromLTRB(0, 0, size.width + 8, size.height));
    centerY = size.height * lyricUI.getPlayingLineBias();
    var drawOffset = centerY + _lyricOffset;
    var lyrics = model?.lyrics ?? [];
    drawOffset -= model?.firstCenterOffset(playingIndex, lyricUI) ?? 0;
    for (var i = 0; i < lyrics.length; i++) {
      var element = lyrics[i];
      // hover 行的背景 (画在文本下层) + 左侧起始时间
      if (hoverColor != null && i == _hoverLineIndex) {
        final hoverRect = getLineRectAt(i, size);
        canvas.drawRRect(hoverRect,
            Paint()..color = hoverColor!.withValues(alpha: hoverOpacity));
        if (hoverTimeColor != null) {
          final timeText = _formatTime(element.startTime ?? 0);
          final tp = TextPainter(
            text: TextSpan(
              text: timeText,
              style: TextStyle(fontSize: 11, color: hoverTimeColor),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            Offset(hoverRect.left + 6,
                hoverRect.center.dy - tp.height / 2),
          );
        }
      }
      var lineHeight = drawLine(i, drawOffset, canvas, element);
      var nextOffset = drawOffset + lineHeight;
      if (centerY > drawOffset && centerY < nextOffset) {
        if (i != centerLyricIndex) {
          centerLyricIndex = i;
          LyricsLog.logD(
              "drawOffset:$drawOffset next:$nextOffset center:$centerY  当前行是：$i 文本：${element.mainText} ");
        }
      }
      drawOffset = nextOffset;
    }
    // 点击涟漪: 从点击点扩散的圆, 裁剪在点击行的框内 (类似 InkWell splash);
    // 扩散阶段 alpha 固定, 抬起后淡出
    if (rippleColor != null &&
        _pressedLineIndex >= 0 &&
        _rippleFade > 0) {
      final pressedRect = getLineRectAt(_pressedLineIndex, size);
      final maxR = math.max(size.width, size.height) * 1.2;
      final radius = _rippleProgress * maxR;
      canvas.save();
      canvas.clipRRect(pressedRect);
      canvas.drawCircle(
          _pressedPoint,
          radius,
          Paint()
              ..color =
                  rippleColor!.withValues(alpha: rippleOpacity * _rippleFade));
      canvas.restore();
    }
  }

  ///计算某行 hover/涟漪框的位置: 文字上下各留 [lineRectPadding] 边距,
  ///水平方向覆盖整个绘制区 (左对齐时歌词从绘制区左端开始)。
  ///
  ///与 [getLineIndexAtY] 一起构成行命中/自定义绘制的扩展点。
  RRect getLineRectAt(int index, Size size) {
    mSize = size;
    final centerY = size.height * lyricUI.getPlayingLineBias();
    var drawOffset = centerY + _lyricOffset;
    final lyrics = model?.lyrics ?? [];
    drawOffset -= model?.firstCenterOffset(playingIndex, lyricUI) ?? 0;
    for (var i = 0; i < index && i < lyrics.length; i++) {
      drawOffset += computeLineHeight(i, lyrics[i]);
    }
    if (index < 0 || index >= lyrics.length) {
      return RRect.fromRectAndRadius(Rect.zero, Radius.zero);
    }
    // 文字上缘: 行顶 (i>0 时含 lineSpace), 框上下各留 lineRectPadding
    final textTop =
        drawOffset + (index == 0 ? 0.0 : lyricUI.getLineSpace());
    final textBottom = drawOffset + computeLineHeight(index, lyrics[index]);
    return RRect.fromRectAndRadius(
      Rect.fromLTRB(
        0,
        textTop - lineRectPadding,
        size.width,
        textBottom + lineRectPadding,
      ),
      Radius.circular(cornerRadius),
    );
  }

  double drawLine(
      int i, double drawOffset, Canvas canvas, LyricsLineModel element) {
    //空行直接返回
    if (!element.hasMain && !element.hasExt) {
      return lyricUI.getBlankLineHeight();
    }
    return _drawOtherLyricLine(canvas, drawOffset, element, i);
  }

  ///毫秒 → MM:SS
  String _formatTime(int ms) {
    final totalSec = ms ~/ 1000;
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  ///命中检测: 返回点击位置 y 对应的歌词行索引, 无命中返回 -1。
  ///与 [paint] 的行定位逻辑保持一致 (含滚动偏移), 用作点击行/自定义
  ///交互的扩展点, 与 [getLineRectAt]/[computeLineHeight] 配套使用。
  int getLineIndexAtY(double y, Size size) {
    if (model == null || model!.lyrics.isEmpty) return -1;
    mSize = size;
    final centerY = size.height * lyricUI.getPlayingLineBias();
    var drawOffset = centerY + _lyricOffset;
    final lyrics = model!.lyrics;
    drawOffset -= model!.firstCenterOffset(playingIndex, lyricUI);
    for (var i = 0; i < lyrics.length; i++) {
      final lineHeight = computeLineHeight(i, lyrics[i]);
      final nextOffset = drawOffset + lineHeight;
      if (y >= drawOffset && y < nextOffset) return i;
      drawOffset = nextOffset;
    }
    return -1;
  }

  ///计算某行绘制高度 (与 [_drawOtherLyricLine] 的高度累加逻辑一致)。
  double computeLineHeight(int lineIndex, LyricsLineModel element) {
    if (!element.hasMain && !element.hasExt) {
      return lyricUI.getBlankLineHeight();
    }
    double h = 0;
    if (lineIndex != 0) {
      h += lyricUI.getLineSpace();
    }
    final isPlay = lineIndex == playingIndex;
    if (element.hasMain) {
      final painter = isPlay
          ? element.drawInfo?.playingMainTextPainter
          : element.drawInfo?.otherMainTextPainter;
      h += painter?.height ?? 0;
    }
    if (element.hasExt) {
      if (element.hasMain) {
        h += lyricUI.getInlineSpace();
      }
      final painter = isPlay
          ? element.drawInfo?.playingExtTextPainter
          : element.drawInfo?.otherExtTextPainter;
      h += painter?.height ?? 0;
    }
    return h;
  }

  ///绘制其他歌词行
  ///返回造成的偏移量值
  double _drawOtherLyricLine(Canvas canvas, double drawOffsetY,
      LyricsLineModel element, int lineIndex) {
    var isPlay = lineIndex == playingIndex;
    var mainTextPainter = (isPlay
        ? element.drawInfo?.playingMainTextPainter
        : element.drawInfo?.otherMainTextPainter);
    var extTextPainter = (isPlay
        ? element.drawInfo?.playingExtTextPainter
        : element.drawInfo?.otherExtTextPainter);
    //该行行高
    double otherLineHeight = 0;
    //第一行不加行间距
    if (lineIndex != 0) {
      otherLineHeight += lyricUI.getLineSpace();
    }
    var nextOffsetY = drawOffsetY + otherLineHeight;
    if (element.hasMain) {
      otherLineHeight += drawText(
          canvas, mainTextPainter, nextOffsetY, isPlay ? element : null);
    }
    if (element.hasExt) {
      //有主歌词时才加内间距
      if (element.hasMain) {
        otherLineHeight += lyricUI.getInlineSpace();
      }
      var extOffsetY = drawOffsetY + otherLineHeight;
      otherLineHeight += drawText(canvas, extTextPainter, extOffsetY);
    }
    return otherLineHeight;
  }

  void drawHighlight(LyricsLineModel model, Canvas canvas, TextPainter? painter,
      Offset offset) {
    if (!model.hasMain) return;
    var tmpHighlightWidth = _highlightWidth;
    model.drawInfo?.inlineDrawList.forEach((element) {
      if (tmpHighlightWidth < 0) {
        return;
      }
      var currentWidth = 0.0;
      if (tmpHighlightWidth >= element.width) {
        currentWidth = element.width;
      } else {
        currentWidth = element.width - (element.width - tmpHighlightWidth);
      }
      tmpHighlightWidth -= currentWidth;
      var dx = offset.dx + element.offset.dx;
      if (lyricUI.getHighlightDirection() == HighlightDirection.RTL) {
        dx += element.width;
        dx -= currentWidth;
      }
      canvas.drawRect(
          Rect.fromLTWH(dx, offset.dy + element.offset.dy - 2, currentWidth,
              element.height + 2),
          lightBlendPaint..color = lyricUI.getLyricHightlightColor());
    });
  }

  var _highlightWidth = 0.0;

  set highlightWidth(double value) {
    _highlightWidth = value;
    refresh();
  }

  double get highlightWidth => _highlightWidth;

  Paint layerPaint = Paint();

  ///绘制文本并返回行高度
  ///when [element] not null,then draw gradient
  double drawText(Canvas canvas, TextPainter? paint, double offsetY,
      [LyricsLineModel? element]) {
    //paint 理论上不可能为空，预期报错
    var lineHeight = paint!.height;
    if (offsetY < 0 - lineHeight || offsetY > mSize.height) {
      return lineHeight;
    }
    var isEnableLight = element != null && lyricUI.enableHighlight();
    var offset = Offset(getLineOffsetX(paint), offsetY);
    if (isEnableLight) {
      canvas.saveLayer(
          Rect.fromLTWH(0, 0, mSize.width, mSize.height), layerPaint);
    }
    paint.paint(canvas, offset);
    if (isEnableLight) {
      drawHighlight(element!, canvas, paint, offset);
      canvas.restore();
    }
    return lineHeight;
  }

  ///获取行绘制横向坐标
  double getLineOffsetX(TextPainter textPainter) {
    switch (lyricUI.getLyricHorizontalAlign()) {
      case LyricAlign.LEFT:
        // 左对齐时行内左边距, 避免歌词紧贴 hover 框左缘
        return lineLeftPadding;
      case LyricAlign.CENTER:
        return (mSize.width - textPainter.width) / 2;
      case LyricAlign.RIGHT:
        return mSize.width - textPainter.width;
      default:
        return (mSize.width - textPainter.width) / 2;
    }
  }

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) {
    return shouldRepaint(oldDelegate);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
