plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    ndkVersion = "27.0.12077973"
    namespace = "com.example.myfridge_test"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.myfridge_test"
        minSdk = flutter.minSdkVersion   
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

   compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
        // Suppress obsolete options warning (Kotlin DSL)
        // ใช้แบบนี้
        // See: https://github.com/gradle/gradle/issues/16979
        // และ https://github.com/gradle/gradle/issues/16979#issuecomment-1014879646
        // แต่ใน Kotlin DSL ยังไม่รองรับโดยตรง
    }


    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
flutter {
    source = "../.."
}
