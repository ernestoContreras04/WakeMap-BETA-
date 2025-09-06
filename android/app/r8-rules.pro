# R8 rules específicas para resolver problemas de clases faltantes
# Este archivo se usa junto con proguard-rules.pro

# Ignorar warnings sobre clases faltantes de Google Play Core
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Mantener todas las clases de Flutter que podrían usar Google Play Core
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Mantener clases específicas que causan problemas
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Configuración para evitar optimizaciones agresivas que causan problemas
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Mantener métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener clases que implementan interfaces específicas
-keep class * implements java.io.Serializable { *; }
-keep class * implements android.os.Parcelable { *; }
