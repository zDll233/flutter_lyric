# lyric_reader
[![flutter_lyric](https://img.shields.io/badge/ozyl-flutterLyric-blue.svg)](https://github.com/ozyl/flutter_lyric)
[![pub package](https://img.shields.io/pub/v/flutter_lyric.svg)](https://pub.dartlang.org/packages/flutter_lyric)
![GitHub](https://img.shields.io/github/license/ozyl/flutter_lyric.svg)

## Feature

- [x] highlight(enhanced&normal)
- [x] translation lyrics
- [x] smooth animation
- [x] custom UI,Parse
- [x] line tap callback (`onTapLine`)
- [x] line hover highlight (`hoverColor` / `hoverOpacity` / `onHoverLineChanged`)
- [x] ripple on tap (`rippleColor` / `rippleOpacity` / ripple durations, clipped to the line rect)
- [x] hit-testing & line rect API (`getLineIndexAtY` / `getLineRectAt` / `computeLineHeight`)

## Show
1.😊[example on web](https://ozyl.github.io/flutter_lyric/)

🇨🇳china[example on web](https://zylvip.gitee.io/flutter_lyric)

2.download example apk:

[Android](https://raw.githubusercontent.com/ozyl/flutter_lyric/master/doc/example_release/example.apk)
[MacOS](https://raw.githubusercontent.com/ozyl/flutter_lyric/master/doc/example_release/example_mac.zip)

3.run example

## Use

view example

## Interactive extensions (since v0.5.0)

```dart
LyricsReader(
  model: model,
  position: position,
  playing: playing,
  lyricUi: lyricUi,
  // 点击歌词行: 行索引 + 该行开始时间
  onTapLine: (index, startTime) {
    // seek(startTime) 等
  },
  // hover 行背景 (null = 不显示)
  hoverColor: Colors.white,
  hoverOpacity: 0.08,
  // hover 行变化回调 (index = -1 表示移出)
  onHoverLineChanged: (index) {},
  // 点击涟漪 (null = 不显示), 裁剪在行框内 (InkWell 风格)
  rippleColor: Colors.black,
  rippleOpacity: 0.25,
  rippleExpandDuration: Duration(milliseconds: 600), // 按住期间持续扩散
  rippleFinishDuration: Duration(milliseconds: 150), // 抬起加速补完
  rippleFadeDuration: Duration(milliseconds: 300),   // 淡出
  // 行框/布局
  cornerRadius: 8,        // 行框圆角
  lineLeftPadding: 12,    // 左对齐时行内左边距
  lineRectPadding: 12,    // 行框上下边距
)
```

Layout/hit-testing extension points (available on `LyricsReaderPaint`):

- `int getLineIndexAtY(double y, Size size)` — 返回点击位置对应的行索引, 与绘制定位完全一致 (含滚动偏移)
- `RRect getLineRectAt(int index, Size size)` — 某行 hover/涟漪框位置
- `double computeLineHeight(int index, LyricsLineModel element)` — 行绘制高度

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Thanks

[boyan01/flutter-netease-music](https://github.com/boyan01/flutter-netease-music) 