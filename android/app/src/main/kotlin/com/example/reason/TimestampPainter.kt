package com.example.reason

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.util.Size
import java.util.Date
import kotlin.math.min

/**
 * Paints the date and time into the bottom right of the video.
 *
 * The overlay canvas is in sensor buffer coordinates, while the player shows the
 * buffer rotated by the use case target rotation. The anchor and the counter
 * rotation below put the text in the same corner of what the viewer sees.
 */
class TimestampPainter(zoneId: String?) {
    private val format = StampFormat.formatter(zoneId)
    private val today = Date()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
    }
    private val boxPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(140, 0, 0, 0)
    }
    private val box = RectF()

    fun draw(canvas: Canvas, size: Size, rotationDegrees: Int, mirrored: Boolean) {
        today.time = System.currentTimeMillis()
        val text = format.format(today)
        val rotation = ((rotationDegrees % 360) + 360) % 360
        val upright = rotation == 90 || rotation == 270
        val frameWidth = if (upright) size.height else size.width
        val frameHeight = if (upright) size.width else size.height
        val shortest = min(frameWidth, frameHeight).toFloat()

        paint.textSize = shortest * 0.045f
        paint.textAlign = if (mirrored) Paint.Align.LEFT else Paint.Align.RIGHT
        val padding = shortest * 0.015f
        val margin = shortest * 0.03f
        val width = paint.measureText(text)
        val metrics = paint.fontMetrics
        val boxWidth = width + padding * 2
        val boxHeight = (metrics.descent - metrics.ascent) + padding * 2

        val anchorX: Float
        val anchorY: Float
        when (rotation) {
            90 -> {
                // Bottom right of the rotated video is the top right of the buffer.
                anchorX = size.width.toFloat()
                anchorY = 0f
            }

            180 -> {
                anchorX = 0f
                anchorY = 0f
            }

            270 -> {
                anchorX = 0f
                anchorY = size.height.toFloat()
            }

            else -> {
                anchorX = size.width.toFloat()
                anchorY = size.height.toFloat()
            }
        }

        canvas.save()
        canvas.translate(anchorX, anchorY)
        canvas.rotate(-rotation.toFloat())
        if (mirrored) canvas.scale(-1f, 1f)
        // In this frame the visible bottom right corner sits at the origin and the
        // content of the video extends towards negative x and y.
        val textX = if (mirrored) margin else -margin
        val baseline = -margin - metrics.descent
        box.set(
            if (mirrored) textX - padding else textX - boxWidth + padding,
            baseline + metrics.ascent - padding,
            if (mirrored) textX + boxWidth - padding else textX + padding,
            baseline + metrics.descent + padding,
        )
        canvas.drawRoundRect(box, padding, padding, boxPaint)
        canvas.drawText(text, textX, baseline, paint)
        canvas.restore()
    }
}
