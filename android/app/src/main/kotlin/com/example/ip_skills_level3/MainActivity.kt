package com.example.ip_skills_level3

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        // スリープ復帰時にFlutter Surfaceを強制再描画してブラックアウトを防止
        // 複数回の遅延再描画で確実に復帰させる
        window?.decorView?.let { decorView ->
            decorView.postDelayed({
                decorView.requestLayout()
                decorView.invalidate()
            }, 50)
            decorView.postDelayed({
                decorView.requestLayout()
                decorView.invalidate()
            }, 150)
            decorView.postDelayed({
                decorView.requestLayout()
                decorView.invalidate()
            }, 300)
        }
    }
}
