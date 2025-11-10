# Flutter specific rules (good practice to include, though often handled by Flutter's plugin)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.*

# Razorpay specific rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * { public void onPayment*(...); }

# Google Pay integration within Razorpay (from previous missing_rules.txt)
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.PaymentsClient
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.Wallet
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.WalletUtils
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Google Play Core / Dynamic Feature Modules (from current missing_rules.txt)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.appupdate.**
-dontwarn com.google.android.play.core.assetpacks.**
-dontwarn com.google.android.play.core.review.**
-dontwarn com.google.android.play.core.common.**
-dontwarn com.google.android.play.core.integrity.**

# Keep the main activity class from being stripped by ProGuard.
-keep class com.mobiking.wholesale.MainActivity { *; }