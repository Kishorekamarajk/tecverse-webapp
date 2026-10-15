# R8 / ProGuard rules for the TEC-VERSE 2026 release build.
# The Flutter Gradle plugin already adds the core Flutter embedding rules;
# the rules below are a safety net for the embedding and the plugins in use.

# --- Flutter embedding & generated plugin registrant ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter references Play Core (deferred components) classes that are not
# bundled in this app.
-dontwarn com.google.android.play.core.**

# --- flutter_secure_storage (Android Keystore / EncryptedSharedPreferences / Tink) ---
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# --- speech_to_text ---
-keep class com.csdcorp.speech_to_text.** { *; }

# --- flutter_tts ---
-keep class com.eyedeadevelopment.fluttertts.** { *; }

# --- url_launcher, shared_preferences, path_provider (Pigeon channels) ---
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# --- package:jni (used by path_provider_android); its own consumer rules also apply ---
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# --- Kotlin metadata / coroutines used by plugins ---
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-dontwarn kotlinx.coroutines.**
