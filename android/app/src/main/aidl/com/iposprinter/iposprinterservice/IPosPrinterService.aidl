package com.iposprinter.iposprinterservice;

import com.iposprinter.iposprinterservice.IPosPrinterCallback;
import android.graphics.Bitmap;

interface IPosPrinterService {
    int getPrinterStatus();

    void printerInit(IPosPrinterCallback cb);

    void setPrinterPrintDepth(int depth, IPosPrinterCallback cb);
    void setPrinterPrintFontType(String typeface, IPosPrinterCallback cb);
    void setPrinterPrintFontSize(int fontsize, IPosPrinterCallback cb);
    void setPrinterPrintAlignment(int alignment, IPosPrinterCallback cb);

    void printerFeedLines(int lines, IPosPrinterCallback cb);
    void printBlankLines(int lines, int height, IPosPrinterCallback cb);

    void printText(String text, IPosPrinterCallback cb);
    void printSpecifiedTypeText(String text, String typeface, int fontsize, IPosPrinterCallback cb);
    void PrintSpecFormatText(String text, String typeface, int fontsize, int alignment, IPosPrinterCallback cb);

    // ⬇️ ¡OJO! Arrays marcados como 'in'
    void printColumnsText(in String[] colsTextArr, in int[] colsWidthArr, in int[] colsAlign, int isContinuousPrint, IPosPrinterCallback cb);

    // ⬇️ ¡OJO! Bitmap marcado como 'in' y con nombre totalmente calificado
    void printBitmap(int alignment, int bitmapSize, in android.graphics.Bitmap mBitmap, IPosPrinterCallback cb);

    void printBarCode(String data, int symbology, int height, int width, int textposition, IPosPrinterCallback cb);
    void printQRCode(String data, int modulesize, int mErrorCorrectionLevel, IPosPrinterCallback cb);

    // ⬇️ ¡OJO! byte[] marcados como 'in'
    void printRawData(in byte[] rawPrintData, IPosPrinterCallback cb);
    void sendUserCMDData(in byte[] data, IPosPrinterCallback cb);

    void printerPerformPrint(int feedlines, IPosPrinterCallback cb);
}
