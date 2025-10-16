package com.example.tester

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import com.iposprinter.iposprinterservice.IPosPrinterCallback
import com.iposprinter.iposprinterservice.IPosPrinterService

class Q3Binder(private val ctx: Context) {

    companion object {
        private const val TAG = "Q3Binder"
        private const val PKG = "com.iposprinter.iposprinterservice"
        private const val SVC = "com.iposprinter.iposprinterservice.IPosPrintService"
        private const val ACTION = "com.iposprinter.iposprinterservice.IPosPrintService"
    }

    // Callback real (solo 2 métodos en este AIDL)
    private val cb = object : IPosPrinterCallback.Stub() {
        override fun onRunResult(isSuccess: Boolean) {
            Log.i(TAG, "onRunResult: $isSuccess")
        }
        override fun onReturnString(value: String?) {
            Log.i(TAG, "onReturnString: $value")
        }
    }

    private var iPrinter: IPosPrinterService? = null
    private var conn: ServiceConnection? = null
    private var lastBinder: IBinder? = null

    var isBound: Boolean = false
        private set

    fun bind(onReady: (() -> Unit)? = null, onFail: ((Throwable) -> Unit)? = null) {
        if (isBound) { onReady?.invoke(); return }

        val intent = Intent(ACTION).apply { component = ComponentName(PKG, SVC) }

        conn = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
                lastBinder = service
                iPrinter = IPosPrinterService.Stub.asInterface(service)

                // Loguea métodos disponibles (útil para diagnosticar)
                try {
                    val cls = iPrinter!!::class.java
                    cls.methods.sortedBy { it.name }.forEach { m ->
                        val params = m.parameterTypes.joinToString(",") { it.name }
                        Log.i(TAG, "AIDL method: ${m.name}($params)")
                    }
                } catch (t: Throwable) {
                    Log.w(TAG, "No pude listar métodos: ${t.message}")
                }

                isBound = true
                onReady?.invoke()
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                isBound = false
                lastBinder = null
                iPrinter = null
            }
        }

        val ok = ctx.bindService(intent, conn!!, Context.BIND_AUTO_CREATE)
        if (!ok) onFail?.invoke(IllegalStateException("bindService=false"))
    }

    fun unbind() {
        conn?.let { ctx.unbindService(it) }
        conn = null
        isBound = false
        lastBinder = null
        iPrinter = null
    }

    fun getInterfaceDescriptor(): String? =
        try { lastBinder?.interfaceDescriptor } catch (_: Throwable) { null }

    // ========= Helpers seguros que siempre pasan callback ==========

    private fun svc(): IPosPrinterService =
        iPrinter ?: throw IllegalStateException("Printer service not bound")

    fun getPrinterStatus(): Int = svc().getPrinterStatus()

    fun init() = svc().printerInit(cb)

    fun setAlignment(alignment: Int) = svc().setPrinterPrintAlignment(alignment, cb)
    fun setFontSize(size: Int) = svc().setPrinterPrintFontSize(size, cb)
    fun setFontType(typeface: String) = svc().setPrinterPrintFontType(typeface, cb)

    fun feedLines(lines: Int) = svc().printerFeedLines(lines, cb)
    fun printBlankLines(lines: Int, height: Int) = svc().printBlankLines(lines, height, cb)

    fun printText(text: String) = svc().printText(text, cb)

    fun printSpecifiedTypeText(text: String, typeface: String, fontsize: Int) =
        svc().printSpecifiedTypeText(text, typeface, fontsize, cb)

    fun printSpecFormatText(text: String, typeface: String, fontsize: Int, alignment: Int) =
        svc().PrintSpecFormatText(text, typeface, fontsize, alignment, cb)

    fun printColumnsText(colsText: Array<String>, colsWidth: IntArray, colsAlign: IntArray, isContinuousPrint: Int) =
        svc().printColumnsText(colsText, colsWidth, colsAlign, isContinuousPrint, cb)

    fun printQRCode(data: String, moduleSize: Int, eccLevel: Int) =
        svc().printQRCode(data, moduleSize, eccLevel, cb)

    fun printBarCode(data: String, symbology: Int, height: Int, width: Int, textPosition: Int) =
        svc().printBarCode(data, symbology, height, width, textPosition, cb)

    fun printRaw(data: ByteArray) = svc().printRawData(data, cb)

    fun performPrint(feedLines: Int) = svc().printerPerformPrint(feedLines, cb)

    // ========== Ejemplo de ticket demo (lo que ya probaste) ==========
    fun printSampleTicket() {
        init()

        setAlignment(1)              // centro
        setFontSize(32)
        setFontType("DEFAULT")
        printText("FUELRED\n")

        setFontSize(22)
        printText("------------------------------\n")

        setAlignment(0)              // izquierda
        val w = intArrayOf(16, 10)
        val a = intArrayOf(0, 2)
        printColumnsText(arrayOf("Producto X", "10.000"), w, a, 0)
        printColumnsText(arrayOf("Producto Y", "5.000"), w, a, 0)
        printText("------------------------------\n")
        setFontSize(28)
        printColumnsText(arrayOf("TOTAL", "15.000"), w, a, 0)

        printBlankLines(2, 25)
        performPrint(120)
    }
}
