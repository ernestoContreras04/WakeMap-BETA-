package com.example.tfg_definitivo2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
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
            if (intent?.action == "com.example.tfg_definitivo2.ACTION_ALARM_STOPPED") {
                eventSink?.success("alarm_stopped")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
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
                eventSink = events
                val intentFilter = IntentFilter("com.example.tfg_definitivo2.ACTION_ALARM_STOPPED")
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ContextCompat.registerReceiver(
                        this@MainActivity,
                        alarmStoppedReceiver,
                        intentFilter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                } else {
                    registerReceiver(alarmStoppedReceiver, intentFilter)
                }
            }

            override fun onCancel(arguments: Any?) {
                unregisterReceiver(alarmStoppedReceiver)
                eventSink = null
            }
        })
    }
}
