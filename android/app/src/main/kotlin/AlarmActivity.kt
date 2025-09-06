package com.example.tfg_definitivo2

import android.app.Activity
import android.content.Intent
import android.media.MediaPlayer
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button

class AlarmActivity : Activity() {
    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        android.util.Log.d("AlarmActivity", "🚀 ALARMACTIVITY CREADA")
        this.title = ""
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        setContentView(R.layout.activity_alarm)

        // COMENTADO: Flutter se encarga de la reproducción de audio
        // mediaPlayer = MediaPlayer.create(this, R.raw.alarma) 
        // mediaPlayer?.isLooping = true
        // mediaPlayer?.start()

        val btnStop = findViewById<Button>(R.id.btnStop)
        btnStop.setOnClickListener {
            android.util.Log.d("AlarmActivity", "🛑 BOTÓN DETENER PRESIONADO")
            
            // COMENTADO: Flutter se encarga de detener el audio
            // mediaPlayer?.stop()
            // mediaPlayer?.release()
            // mediaPlayer = null
            
            // SOLUCIÓN ALTERNATIVA: Usar Intent directo a MainActivity
            android.util.Log.d("AlarmActivity", "📡 ENVIANDO INTENT DIRECTO A MAINACTIVITY")
            val intent = Intent(this, com.example.tfg_definitivo2.MainActivity::class.java)
            intent.putExtra("ACTION", "ALARM_STOPPED")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
            
            android.util.Log.d("AlarmActivity", "✅ INTENT ENVIADO - Cerrando actividad")
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // COMENTADO: Flutter se encarga de detener el audio
        // mediaPlayer?.stop()
        // mediaPlayer?.release()
        // mediaPlayer = null
    }
}
