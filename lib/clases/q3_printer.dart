import 'package:flutter/services.dart';

class Q3Printer {
  static const _ch = MethodChannel('q3pro/printer');

  static Future<bool> bind() async =>
      (await _ch.invokeMethod<bool>('bind')) ?? false;

  static Future<void> unbind() =>
      _ch.invokeMethod<void>('unbind');

  static Future<String> descriptor() async =>
      (await _ch.invokeMethod<String>('descriptor')) ?? '';

  static Future<int> status() async =>
      (await _ch.invokeMethod<int>('status')) ?? -1;

  static Future<void> init() =>
      _ch.invokeMethod<void>('init');

  static Future<void> setAlignment(int a) =>
      _ch.invokeMethod<void>('setAlignment', {'alignment': a});

  static Future<void> setFontSize(int s) =>
      _ch.invokeMethod<void>('setFontSize', {'size': s});

  static Future<void> setFontType(String t) =>
      _ch.invokeMethod<void>('setFontType', {'typeface': t});

  static Future<void> feedLines(int n) =>
      _ch.invokeMethod<void>('feedLines', {'lines': n});

  static Future<void> printBlankLines(int lines, int height) =>
      _ch.invokeMethod<void>('printBlankLines', {'lines': lines, 'height': height});

  static Future<void> printText(String text) =>
      _ch.invokeMethod<void>('printText', {'text': text});

  static Future<void> printColumnsText(
    List<String> texts,
    List<int> widths,
    List<int> aligns, {
    int continuous = 0,
  }) =>
      _ch.invokeMethod<void>('printColumnsText', {
        'texts': texts,
        'widths': widths,
        'aligns': aligns,
        'continuous': continuous,
      });

  static Future<void> printQR(String data, {int moduleSize = 7, int eccLevel = 2}) =>
      _ch.invokeMethod<void>('printQR', {
        'data': data,
        'moduleSize': moduleSize,
        'eccLevel': eccLevel,
      });

  static Future<void> printBarCode(
    String data, {
    int symbology = 8,
    int height = 80,
    int width = 2,
    int textPosition = 2,
  }) =>
      _ch.invokeMethod<void>('printBarCode', {
        'data': data,
        'symbology': symbology,
        'height': height,
        'width': width,
        'textPosition': textPosition,
      });

  static Future<void> printRaw(Uint8List data) =>
      _ch.invokeMethod<void>('printRaw', {'data': data});

  static Future<void> performPrint(int feedlines) =>
      _ch.invokeMethod<void>('performPrint', {'feedlines': feedlines});

  static Future<void> printSample() =>
      _ch.invokeMethod<void>('printSample');

  static Future<void> printSpecFormatText({
    required String text,
    String typeface = 'DEFAULT',
    int fontsize = 24,
    int alignment = 0,
  }) =>
      _ch.invokeMethod<void>('printSpecFormatText', {
        'text': text,
        'typeface': typeface,
        'fontsize': fontsize,
        'alignment': alignment,
      });    
}
