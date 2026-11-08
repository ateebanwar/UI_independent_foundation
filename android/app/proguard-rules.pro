# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Echo Bloom Native Services & Receivers
-keep class com.antigravity.echo_bloom.** { *; }
-keepclassmembers class com.antigravity.echo_bloom.** { *; }

# SQLite / Sqflite
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }

# Android Media & Notifications
-keep class android.media.session.** { *; }
-keep class android.media.audiofx.** { *; }

# Suppress Google Play Core deferred components warnings (not using Play Store dynamic features)
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
