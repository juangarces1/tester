

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VariosHelpers {
  static  String capitalize(String text) {
    if (text.isEmpty) return "";
    return text[0].toUpperCase() + text.substring(1);
  }

 static String convertCamelCaseToTitle(String text) {
    if (text.isEmpty) return text;

    String result = text[0].toUpperCase();
    for (int i = 1; i < text.length; i++) {
      if (text[i].toUpperCase() == text[i]) {
        result += ' ';
      }
      result += text[i];
    }

    return result.replaceAllMapped(
      RegExp(r'([A-Z])'), 
      (Match m) => m[0]!.toUpperCase()
    );
  }

  static Color getShadedColor(String key, Color baseColor) {
    int hash = key.hashCode;
    double luminanceAdjustment = (hash % 100) / 1000; // Ajusta este valor para un cambio más leve
    HSLColor hsl = HSLColor.fromColor(baseColor);
    double adjustedLightness = (hsl.lightness + luminanceAdjustment).clamp(0.0, 1.0);

    // Evita que se vuelva demasiado claro
    if (adjustedLightness > 0.8) {
      adjustedLightness = 0.8;
    }

    HSLColor hslAdjusted = hsl.withLightness(adjustedLightness);

    return hslAdjusted.toColor();
  }

  static String formatYYYYmmDD(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  static  String formattedToCurrencyValue(String value) {
   
    double? valorActualizado = double.tryParse(value);
    if (valorActualizado != null) {
        return NumberFormat.currency(locale: 'es_CR', symbol: '¢').format(valorActualizado);            
      } else{
        return value;
      }
  }

  static  String formattedToVolumenValue(String value) {
   
    double? valorActualizado = double.tryParse(value);
    if (valorActualizado != null) {
        return NumberFormat("###,000", "en_US").format(valorActualizado);          
      } else{
        return value;
      }
  }

  static String formatYYYYmmDDhhMMss(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
    return formatter.format(date);
  }

   static String formatYYYYmmDDhhMM(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm');
    return formatter.format(date);
  }

   static String formatToHour(DateTime date) {
    final DateFormat formatter = DateFormat('hh:mm:ss');
    return formatter.format(date);
  }

              
  
}