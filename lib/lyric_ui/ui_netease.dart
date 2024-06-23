import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';

///Sample Netease style
///should be extends LyricUI implementation your own UI.
///this property only for change UI,if not demand just only overwrite methods.
class UINetease extends LyricUI {
  double defaultSize;
  double defaultExtSize;
  double otherMainSize;
  Color defaultColor;
  Color defaultExtColor;
  Color otherMainColor;
  double bias;
  double lineGap;
  double inlineGap;
  LyricAlign lyricAlign;
  LyricBaseLine lyricBaseLine;
  bool highlight;
  Color? highLightTextColor;
  HighlightDirection highlightDirection;

  UINetease({
    this.defaultSize = 18,
    this.defaultExtSize = 14,
    this.otherMainSize = 16,
    this.defaultColor = Colors.white,
    this.defaultExtColor = Colors.white30,
    this.otherMainColor = Colors.white70,
    
    this.bias = 0.5,
    this.lineGap = 25,
    this.inlineGap = 25,
    this.lyricAlign = LyricAlign.CENTER,
    this.lyricBaseLine = LyricBaseLine.CENTER,
    this.highlight = true,
    this.highLightTextColor,
    this.highlightDirection = HighlightDirection.LTR,
  });

  UINetease.clone(UINetease uiNetease)
      : this(
          defaultSize: uiNetease.defaultSize,
          defaultExtSize: uiNetease.defaultExtSize,
          otherMainSize: uiNetease.otherMainSize,
          defaultColor: uiNetease.defaultColor,
          defaultExtColor: uiNetease.defaultExtColor,
          otherMainColor: uiNetease.otherMainColor,

          bias: uiNetease.bias,
          lineGap: uiNetease.lineGap,
          inlineGap: uiNetease.inlineGap,
          lyricAlign: uiNetease.lyricAlign,
          lyricBaseLine: uiNetease.lyricBaseLine,
          highlight: uiNetease.highlight,
          highlightDirection: uiNetease.highlightDirection,
        );

  @override
  TextStyle getPlayingExtTextStyle() =>
      TextStyle(color: defaultExtColor, fontSize: defaultExtSize);

  @override
  TextStyle getOtherExtTextStyle() => TextStyle(
        color: defaultExtColor,
        fontSize: defaultExtSize,
      );

  @override
  TextStyle getOtherMainTextStyle() =>
      TextStyle(color: otherMainColor, fontSize: otherMainSize);

  @override
  TextStyle getPlayingMainTextStyle() => TextStyle(
        color: defaultColor,
        fontSize: defaultSize,
      );

  @override
  double getInlineSpace() => inlineGap;

  @override
  double getLineSpace() => lineGap;

  @override
  double getPlayingLineBias() => bias;

  @override
  LyricAlign getLyricHorizontalAlign() => lyricAlign;

  @override
  LyricBaseLine getBiasBaseLine() => lyricBaseLine;

  @override
  bool enableHighlight() => highlight;

  @override
  HighlightDirection getHighlightDirection() => highlightDirection;

  @override
  Color getLyricHightlightColor() =>
      highLightTextColor ?? super.getLyricHightlightColor();
}
