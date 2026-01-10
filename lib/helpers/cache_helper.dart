import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CacheHelper {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName.json');
  }

  static Future<void> saveCache(String fileName, String content) async {
    try {
      final file = await _getLocalFile(fileName);
      await file.writeAsString(content);
      debugPrint('Cache saved: $fileName');
    } catch (e) {
      debugPrint('Error saving cache $fileName: $e');
    }
  }

  static Future<String?> loadCache(String fileName) async {
    try {
      final file = await _getLocalFile(fileName);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  static Future<void> clearCache(String fileName) async {
    try {
      final file = await _getLocalFile(fileName);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // ignore
    }
  }
}
