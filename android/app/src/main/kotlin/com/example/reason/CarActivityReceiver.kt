package com.example.reason

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class CarActivityReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        CarDetector.current?.onActivityTransition(intent)
    }
}
