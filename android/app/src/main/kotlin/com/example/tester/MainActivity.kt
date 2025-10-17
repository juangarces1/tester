package com.example.tester

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "q3pro/printer"
    }

    private lateinit var binder: Q3Binder

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binder = Q3Binder(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {

                        // ==== Conexión ====
                        "bind" -> {
                            Log.i(TAG, "bind() solicitado")
                            binder.bind(
                                onReady = {
                                    Log.i(TAG, "bind() OK; isBound=${binder.isBound}")
                                    result.success(true)
                                },
                                onFail = { e ->
                                    Log.e(TAG, "bind() FAIL: ${e.message}", e)
                                    result.error("BIND_FAIL", e.message, null)
                                }
                            )
                        }

                        "unbind" -> {
                            Log.i(TAG, "unbind() solicitado")
                            binder.unbind()
                            result.success(true)
                        }

                        "descriptor" -> {
                            val d = binder.getInterfaceDescriptor()
                            Log.i(TAG, "descriptor => $d")
                            result.success(d ?: "")
                        }

                        "status" -> {
                            ensureBound()
                            val st = binder.getPrinterStatus()
                            result.success(st)
                        }

                        // ==== Config & util ====
                        "init" -> { ensureBound(); binder.init(); result.success(true) }
                        "setAlignment" -> {                            
                            val al = call.argument<Int>("alignment") ?: 0
                            binder.setAlignment(al)
                            result.success(true)
                        }
                        "setFontSize" -> {                            
                            val size = call.argument<Int>("size") ?: 24
                            binder.setFontSize(size)
                            result.success(true)
                        }
                        "setFontType" -> {                            
                            val tf = call.argument<String>("typeface") ?: "DEFAULT"
                            binder.setFontType(tf)
                            result.success(true)
                        }
                        "feedLines" -> {                            
                            val lines = call.argument<Int>("lines") ?: 1
                            binder.feedLines(lines)
                            result.success(true)
                        }
                        "printBlankLines" -> {                            
                            val lines = call.argument<Int>("lines") ?: 1
                            val height = call.argument<Int>("height") ?: 25
                            binder.printBlankLines(lines, height)
                            result.success(true)
                        }

                        // ==== Impresión ====
                        "printText" -> {                            
                            val text = call.argument<String>("text") ?: ""
                            binder.printText(text)
                            result.success(true)
                        }

                        "printColumnsText" -> {                            
                            val texts = call.argument<List<String>>("texts") ?: emptyList()
                            val widths = call.argument<List<Int>>("widths") ?: emptyList()
                            val aligns = call.argument<List<Int>>("aligns") ?: emptyList()
                            val cont = call.argument<Int>("continuous") ?: 0
                            if (texts.isEmpty() || widths.isEmpty() || aligns.isEmpty()) {
                                result.error("ARG_ERROR", "texts/widths/aligns requeridos", null)
                                return@setMethodCallHandler
                            }
                            binder.printColumnsText(
                                texts.toTypedArray(),
                                widths.toIntArray(),
                                aligns.toIntArray(),
                                cont
                            )
                            result.success(true)
                        }

                        "printQR" -> {                            
                            val data = call.argument<String>("data") ?: ""
                            val size = call.argument<Int>("moduleSize") ?: 6
                            val ecc  = call.argument<Int>("eccLevel") ?: 2
                            binder.printQRCode(data, size, ecc)
                            result.success(true)
                        }

                        "printBarCode" -> {                            
                            val data = call.argument<String>("data") ?: ""
                            val sym  = call.argument<Int>("symbology") ?: 8
                            val h    = call.argument<Int>("height") ?: 80
                            val w    = call.argument<Int>("width") ?: 2
                            val tp   = call.argument<Int>("textPosition") ?: 2
                            binder.printBarCode(data, sym, h, w, tp)
                            result.success(true)
                        }

                        "printRaw" -> {                            
                            val bytes = call.argument<ByteArray>("data")
                            if (bytes == null) {
                                result.error("ARG_ERROR", "data (ByteArray) requerido", null)
                                return@setMethodCallHandler
                            }
                            binder.printRaw(bytes)
                            result.success(true)
                        }

                        "performPrint" -> {                            
                            val feed = call.argument<Int>("feedlines") ?: 120
                            binder.performPrint(feed)
                            result.success(true)
                        }

                        // Demo lista para usar desde Flutter
                        "printSample" -> {                           
                            binder.printSampleTicket()
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (t: Throwable) {
                    Log.e(TAG, "call=${call.method} FAIL: ${t.message}", t)
                    result.error("NATIVE_FAIL", t.message, null)
                }
            }
    }

    private fun ensureBound() {
        if (!binder.isBound) throw IllegalStateException("Printer service not bound")
    }

    override fun onDestroy() {
        binder.unbind()
        super.onDestroy()
    }
}
