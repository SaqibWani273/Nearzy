# Razorpay checkout — https://razorpay.com/docs/payments/payment-gateway/android-integration/standard/troubleshoot/
-keepattributes *Annotation*
-keepattributes JavascriptInterface
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
-keepclassmembers class * {
  @android.webkit.JavascriptInterface <methods>;
}

-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers
