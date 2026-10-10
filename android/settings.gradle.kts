try {
    val processEnv = Class.forName("java.lang.ProcessEnvironment")

    val theEnvironment = processEnv.getDeclaredField("theEnvironment")
    theEnvironment.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val envMap = theEnvironment.get(null) as MutableMap<String, String>
    envMap.remove("ANDROID_PREFS_ROOT")
    envMap.remove("ANDROID_SDK_HOME")

    val theCaseInsensitiveEnvironment = processEnv.getDeclaredField("theCaseInsensitiveEnvironment")
    theCaseInsensitiveEnvironment.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val caseInsensitiveMap = theCaseInsensitiveEnvironment.get(null) as MutableMap<String, String>
    caseInsensitiveMap.remove("ANDROID_PREFS_ROOT")
    caseInsensitiveMap.remove("ANDROID_SDK_HOME")
} catch (_: Exception) {}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
