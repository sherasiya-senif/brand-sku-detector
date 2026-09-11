package com.example.brand_sku_detector

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * The activity shown inside the expanded conversation bubble (Method 2).
 *
 * Kept intentionally small and native so it embeds cleanly in the system bubble
 * window. Its single action brings the SKU detector to the foreground.
 */
class BubbleActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val pad = (16 * resources.displayMetrics.density).toInt()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            setPadding(pad, pad, pad, pad)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }

        root.addView(
            TextView(this).apply {
                text = "SKU Assistant"
                textSize = 20f
                setTextColor(Color.BLACK)
            },
        )

        root.addView(
            TextView(this).apply {
                text = "Quick access to the shelf detector."
                textSize = 14f
                setTextColor(Color.DKGRAY)
                setPadding(0, pad / 2, 0, pad)
            },
        )

        root.addView(
            Button(this).apply {
                text = "Open SKU Detector"
                setOnClickListener {
                    startActivity(
                        Intent(this@BubbleActivity, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                }
            },
        )

        root.addView(
            Button(this).apply {
                text = "Close"
                setOnClickListener { finish() }
            },
        )

        root.gravity = Gravity.CENTER_VERTICAL
        setContentView(root)
    }
}
