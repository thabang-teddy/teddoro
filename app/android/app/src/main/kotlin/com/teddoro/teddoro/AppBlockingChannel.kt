package com.teddoro.teddoro

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Native half of the `teddoro/app_blocking` method channel.
 *
 * Real app blocking on Android needs an AccessibilityService (the Digital
 * Wellbeing / Focus Mode APIs are not public). That service is not
 * implemented yet, so this reports `isSupported = false` and the Dart UI
 * hides the feature. To enable it:
 *
 *  1. Add a BlockingAccessibilityService that watches window changes and
 *     sends the user home when a blocked package comes to the foreground.
 *  2. Return true from `isSupported`, and prompt for the accessibility
 *     permission from `setBlocking` when it is missing.
 *  3. Implement `pickApps` with a package-list picker activity.
 */
object AppBlockingChannel {
    private const val NAME = "teddoro/app_blocking"

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(false)
                "pickApps" -> result.success(call.argument<List<String>>("current") ?: emptyList<String>())
                "setBlocking" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }
}
