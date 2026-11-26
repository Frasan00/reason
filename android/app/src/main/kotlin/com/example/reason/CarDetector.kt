package com.example.reason

import android.Manifest
import android.app.PendingIntent
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.hardware.TriggerEvent
import android.hardware.TriggerEventListener
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

/**
 * Best-effort "in the car" detection, cheapest source first: a car audio
 * Bluetooth link, charging plus significant motion, then Google's batched
 * vehicle transitions. Every source only arms while [start] is active.
 */
class CarDetector(
    private val context: Context,
    private var signals: Signals,
    private val onEnter: (Int) -> Unit,
    private val onExit: () -> Unit,
) {
    data class Signals(
        val bluetooth: Boolean,
        val motion: Boolean,
        val activity: Boolean,
    )

    companion object {
        const val ACTIVITY_ACTION = "com.example.reason.action.CAR_ACTIVITY"

        @Volatile
        var current: CarDetector? = null
            private set

        private const val EXIT_DELAY_MS = 60_000L
        private const val MOTION_REARM_MS = 60_000L
        private const val CAR_AUDIO = BluetoothClass.Device.AUDIO_VIDEO_CAR_AUDIO
        private const val HANDSFREE = BluetoothClass.Device.AUDIO_VIDEO_HANDSFREE
    }

    private val handler = Handler(Looper.getMainLooper())
    private val sensorManager = context.getSystemService(SensorManager::class.java)
    private val carDevices = mutableSetOf<String>()
    private var activityCar = false
    private var charging = false
    private var lastMotion = 0L
    private var inCar = false
    private var exitPending = false
    private var active = false

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (!bluetoothAllowed()) return
            @Suppress("DEPRECATION")
            val device = intent.getParcelableExtra<BluetoothDevice>(
                BluetoothDevice.EXTRA_DEVICE,
            ) ?: return
            val isCar = runCatching {
                val minor = device.bluetoothClass?.deviceClass
                minor == CAR_AUDIO || minor == HANDSFREE
            }.getOrDefault(false)
            if (!isCar) return
            if (intent.action == BluetoothDevice.ACTION_ACL_CONNECTED) {
                carDevices.add(device.address)
            } else {
                carDevices.remove(device.address)
            }
            evaluate()
        }
    }

    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val connected = intent.action == Intent.ACTION_POWER_CONNECTED
            charging = connected
            if (connected) {
                armMotion()
            } else {
                disarmMotion()
                lastMotion = 0L
            }
            evaluate()
        }
    }

    private val rearmMotion = Runnable { armMotion() }

    private val motionListener = object : TriggerEventListener() {
        override fun onTrigger(event: TriggerEvent) {
            lastMotion = SystemClock.elapsedRealtime()
            evaluate()
            handler.postDelayed(rearmMotion, MOTION_REARM_MS)
        }
    }

    private val exitRunnable = Runnable {
        exitPending = false
        if (active && !inCarNow() && inCar) {
            inCar = false
            onExit()
        }
    }

    fun start() {
        if (active) return
        active = true
        current = this
        runCatching {
            ContextCompat.registerReceiver(
                context,
                bluetoothReceiver,
                IntentFilter().apply {
                    addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
                    addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
                },
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
            ContextCompat.registerReceiver(
                context,
                powerReceiver,
                IntentFilter().apply {
                    addAction(Intent.ACTION_POWER_CONNECTED)
                    addAction(Intent.ACTION_POWER_DISCONNECTED)
                },
                ContextCompat.RECEIVER_NOT_EXPORTED,
            )
        }
        charging = isCharging()
        if (signals.motion && charging) armMotion()
        if (signals.activity) requestActivityTransitions()
        evaluate()
    }

    fun stop() {
        if (!active) return
        // Turning car mode off must also end a drive it started.
        if (inCar) onExit()
        active = false
        handler.removeCallbacksAndMessages(null)
        runCatching { context.unregisterReceiver(bluetoothReceiver) }
        runCatching { context.unregisterReceiver(powerReceiver) }
        disarmMotion()
        removeActivityTransitions()
        carDevices.clear()
        activityCar = false
        charging = false
        lastMotion = 0L
        inCar = false
        exitPending = false
        if (current === this) current = null
    }

    fun updateSignals(next: Signals) {
        val previous = signals
        signals = next
        if (!next.motion) {
            disarmMotion()
            lastMotion = 0L
        } else if (charging) {
            armMotion()
        }
        if (next.activity != previous.activity) {
            if (next.activity) {
                requestActivityTransitions()
            } else {
                activityCar = false
                removeActivityTransitions()
            }
        }
        evaluate()
    }

    fun onActivityTransition(intent: Intent) {
        if (!active || !signals.activity) return
        val result = runCatching {
            ActivityTransitionResult.extractResult(intent)
        }.getOrNull() ?: return
        for (event in result.transitionEvents) {
            if (event.activityType != DetectedActivity.IN_VEHICLE) continue
            activityCar =
                event.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER
        }
        evaluate()
    }

    private fun inCarNow(): Boolean = CarSignals.inCar(
        if (signals.bluetooth) carDevices.size else 0,
        signals.activity && activityCar,
        signals.motion && charging,
        if (signals.motion) lastMotion else 0L,
        SystemClock.elapsedRealtime(),
    )

    private fun reason(): Int = when {
        signals.bluetooth && carDevices.isNotEmpty() -> R.string.car_reason_bluetooth
        signals.motion && recentMotion() -> R.string.car_reason_motion
        signals.activity && activityCar -> R.string.car_reason_google
        else -> R.string.car_reason_other
    }

    private fun recentMotion(): Boolean =
        charging && lastMotion > 0L &&
            SystemClock.elapsedRealtime() - lastMotion <
            CarSignals.MOTION_HOLD_MS

    private fun evaluate() {
        if (!active) return
        if (inCarNow()) {
            exitPending = false
            handler.removeCallbacks(exitRunnable)
            if (!inCar) {
                inCar = true
                onEnter(reason())
            }
        } else if (inCar && !exitPending) {
            exitPending = true
            handler.postDelayed(exitRunnable, EXIT_DELAY_MS)
        }
    }

    private fun bluetoothAllowed(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT,
            ) == PackageManager.PERMISSION_GRANTED

    private fun isCharging(): Boolean {
        val manager = context.getSystemService(BatteryManager::class.java)
            ?: return false
        return manager.isCharging
    }

    private fun armMotion() {
        val manager = sensorManager ?: return
        if (!active || !charging || !signals.motion) return
        val sensor = manager.getDefaultSensor(Sensor.TYPE_SIGNIFICANT_MOTION)
            ?: return
        runCatching { manager.requestTriggerSensor(motionListener, sensor) }
    }

    private fun disarmMotion() {
        handler.removeCallbacks(rearmMotion)
        val manager = sensorManager ?: return
        val sensor = manager.getDefaultSensor(Sensor.TYPE_SIGNIFICANT_MOTION)
            ?: return
        runCatching { manager.cancelTriggerSensor(motionListener, sensor) }
    }

    private fun requestActivityTransitions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val transitions = listOf(
            transition(ActivityTransition.ACTIVITY_TRANSITION_ENTER),
            transition(ActivityTransition.ACTIVITY_TRANSITION_EXIT),
        )
        runCatching {
            ActivityRecognition.getClient(context).requestActivityTransitionUpdates(
                ActivityTransitionRequest(transitions),
                transitionsPendingIntent(),
            )
        }
    }

    private fun removeActivityTransitions() {
        runCatching {
            ActivityRecognition.getClient(context)
                .removeActivityTransitionUpdates(transitionsPendingIntent())
        }
    }

    private fun transition(type: Int): ActivityTransition =
        ActivityTransition.Builder()
            .setActivityType(DetectedActivity.IN_VEHICLE)
            .setActivityTransition(type)
            .build()

    private fun transitionsPendingIntent(): PendingIntent {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
        return PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, CarActivityReceiver::class.java)
                .setAction(ACTIVITY_ACTION),
            flags,
        )
    }
}
