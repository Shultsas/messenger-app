plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.messenger_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.messenger_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

        buildTypes {
        getByName("release") {
            // Включаем отладочную подпись, чтобы не возиться с ключами прямо сейчас
            signingConfig = signingConfigs.getByName("debug")
            
            // Отключаем минификацию и обфускацию, чтобы избежать ошибок компиляции Kotlin
            isMinifyEnabled = false
            isShrinkResources = false
            
            // ProGuard правила (если нужны, пока оставим пустым или стандартным)
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            }
         }
}

flutter {
    source = "../.."
}
