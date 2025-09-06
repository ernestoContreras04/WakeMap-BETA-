package com.example.tfg_definitivo2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.tfg_definitivo2/alarm"
    private val EVENT_CHANNEL = "com.example.tfg_definitivo2/alarm/events"

    private var eventSink: EventChannel.EventSink? = null

    private val alarmStoppedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            android.util.Log.d("MainActivity", "📡 BROADCAST RECIBIDO: ${intent?.action}")
            if (intent?.action == "com.example.tfg_definitivo2.ACTION_ALARM_STOPPED") {
                android.util.Log.d("MainActivity", "✅ BROADCAST CORRECTO - Enviando evento a Flutter")
                eventSink?.success("alarm_stopped")
                android.util.Log.d("MainActivity", "✅ EVENTO ENVIADO A FLUTTER: alarm_stopped")
            } else {
                android.util.Log.d("MainActivity", "⚠️ BROADCAST INCORRECTO: ${intent?.action}")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("MainActivity", "🚀 MAINACTIVITY CREADA")
        _handleAlarmStoppedIntent()
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        android.util.Log.d("MainActivity", "🔄 MAINACTIVITY - NUEVO INTENT RECIBIDO")
        setIntent(intent)
        _handleAlarmStoppedIntent()
    }
    
    private fun _handleAlarmStoppedIntent() {
        val action = intent.getStringExtra("ACTION")
        if (action == "ALARM_STOPPED") {
            android.util.Log.d("MainActivity", "🛑 RECIBIDO INTENT DE ALARMACTIVITY - Enviando evento a Flutter")
            // Enviar evento a Flutter
            if (eventSink != null) {
                eventSink?.success("alarm_stopped")
                android.util.Log.d("MainActivity", "✅ EVENTO ENVIADO A FLUTTER: alarm_stopped")
            } else {
                android.util.Log.d("MainActivity", "⚠️ EVENTSINK ES NULL - No se puede enviar evento")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        android.util.Log.d("MainActivity", "🚀 MAINACTIVITY CONFIGURADA")
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startAlarm") {
                val intent = Intent(this, AlarmActivity::class.java)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                android.util.Log.d("MainActivity", "🎧 REGISTRANDO BROADCAST RECEIVER")
                eventSink = events
                val intentFilter = IntentFilter("com.example.tfg_definitivo2.ACTION_ALARM_STOPPED")
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    android.util.Log.d("MainActivity", "📱 Android 13+ - Registrando receiver")
                    ContextCompat.registerReceiver(
                        this@MainActivity,
                        alarmStoppedReceiver,
                        intentFilter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                } else {
                    android.util.Log.d("MainActivity", "📱 Android <13 - Registrando receiver")
                    registerReceiver(alarmStoppedReceiver, intentFilter)
                }
                android.util.Log.d("MainActivity", "✅ BROADCAST RECEIVER REGISTRADO CORRECTAMENTE")
            }

            override fun onCancel(arguments: Any?) {
                android.util.Log.d("MainActivity", "🛑 CANCELANDO BROADCAST RECEIVER")
                unregisterReceiver(alarmStoppedReceiver)
                eventSink = null
                android.util.Log.d("MainActivity", "✅ BROADCAST RECEIVER CANCELADO")
            }
        })
    }
}
