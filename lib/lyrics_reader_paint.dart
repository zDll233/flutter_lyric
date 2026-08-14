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

  ///hover 行边框色 (null = 不显示 hover 效果)
  Color? hoverColor;

  ///点击涟漪颜色 (null = 不显示涟漪)
  Color? rippleColor;

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
    //溢出裁剪
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    centerY = size.height * lyricUI.getPlayingLineBias();
    var drawOffset = centerY + _lyricOffset;
    var lyrics = model?.lyrics ?? [];
    drawOffset -= model?.firstCenterOffset(playingIndex, lyricUI) ?? 0;
    for (var i = 0; i < lyrics.length; i++) {
      var element = lyrics[i];
      // hover 行的背景与边框 (画在文本下层);
      // 行距只加在行顶导致文字在行区间内偏下, 框上下各让出 lineSpace/2 使文字居中
      if (hoverColor != null && i == _hoverLineIndex) {
        final lineSpace = i == 0 ? 0.0 : lyricUI.getLineSpace();
        final hoverRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(0, drawOffset + lineSpace / 2, size.width,
              drawOffset + computeLineHeight(i, element) + lineSpace / 2),
          const Radius.circular(8),
        );
        canvas.drawRRect(hoverRect,
            Paint()..color = hoverColor!.withValues(alpha: 0.08));
        canvas.drawRRect(
            hoverRect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = hoverColor!.withValues(alpha: 0.22));
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
    // 点击涟漪: 从点击点扩散的圆, 随进度渐隐
    if (rippleColor != null &&
        _pressedLineIndex >= 0 &&
        _rippleProgress > 0 &&
        _rippleProgress < 1) {
      final maxR = math.max(size.width, size.height) * 1.2;
      final radius = _rippleProgress * maxR;
      final alpha = (1 - _rippleProgress).clamp(0.0, 1.0) * 0.35;
      canvas.drawCircle(
          _pressedPoint,
          radius,
          Paint()..color = rippleColor!.withValues(alpha: alpha));
    }
  }

  double drawLine(
      int i, double drawOffset, Canvas canvas, LyricsLineModel element) {
    //空行直接返回
    if (!element.hasMain && !element.hasExt) {
      return lyricUI.getBlankLineHeight();
    }
    return _drawOtherLyricLine(canvas, drawOffset, element, i);
  }

  ///命中检测: 返回点击位置 y 对应的歌词行索引, 无命中返回 -1。
  ///与 [paint] 的行定位逻辑保持一致 (含滚动偏移)。
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
        return 0;
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
