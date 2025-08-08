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
        this.title = ""
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        setContentView(R.layout.activity_alarm)

        mediaPlayer = MediaPlayer.create(this, R.raw.alarma) 
        mediaPlayer?.isLooping = true
        mediaPlayer?.start()

        val btnStop = findViewById<Button>(R.id.btnStop)
        btnStop.setOnClickListener {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
            val intent = Intent("com.example.tfg_definitivo2.ACTION_ALARM_STOPPED")
            sendBroadcast(intent)
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }
}
