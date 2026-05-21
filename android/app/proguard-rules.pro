# Flutter default ProGuard rules
# https://flutter.dev/to/obfuscating-dart-code

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Google Play Core (required by Flutter)
-keep class com.google.android.play.core.** { *; }

# Keep Health Connect classes
-keep class androidx.health.connect.** { *; }

# Keep Firebase / Crashlytics
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Dart/Flutter reflection
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
