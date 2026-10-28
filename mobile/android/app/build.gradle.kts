import java.util.Properties
import java.io.FileInputStream
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing credentials from android/key.properties.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "in.cdac.tecverse.tec_app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?: throw GradleException("keyAlias is missing in key.properties")

                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?: throw GradleException("keyPassword is missing in key.properties")

                storePassword = keystoreProperties.getProperty("storePassword")
                    ?: throw GradleException("storePassword is missing in key.properties")

                val keystorePath = keystoreProperties.getProperty("storeFile")
                    ?: throw GradleException("storeFile is missing in key.properties")

                // Resolve the keystore path relative to the Android app module.
                storeFile = file(keystorePath)
            }
        }
    }

    defaultConfig {
        applicationId = "in.cdac.tecverse.tec_app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // Version name and version code are taken from pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // Debug builds use the standard debug signing configuration.
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            // Require a release keystore for Play Store builds.
            if (!hasReleaseKeystore) {
                throw GradleException(
                    "Release keystore not found. Create android/key.properties " +
                    "and configure your upload keystore before building a release."
                )
            }

            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}