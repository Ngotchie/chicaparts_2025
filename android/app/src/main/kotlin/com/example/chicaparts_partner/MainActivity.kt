package com.mayem_solutions.chicaparts

import android.os.Bundle
import android.graphics.Color
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Changer la couleur de la status bar pour qu’elle corresponde au splash
        window.statusBarColor = Color.parseColor("#244B6B") // ou la même que dans @color/primary_splash
    }
}
