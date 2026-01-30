package com.example.ip_skills_level3

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        // スリープ復帰時にFlutter Surfaceを強制再描画してブラックアウトを防止
        window?.decorView?.postDelayed({
            window?.decorView?.requestLayout()
            window?.decorView?.invalidate()
        }, 100)
    }
}
