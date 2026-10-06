import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Llave de release real (android/upload-keystore.jks) — key.properties nunca se sube a git
// (ver android/.gitignore). Sin ese archivo, cae de vuelta a la llave de debug para que
// `flutter run` y los builds de desarrollo sigan funcionando sin necesitarlo.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.globalappsuite.revendo"
    compileSdk = flutter.compileSdkVersion
    // flutter.ndkVersion se calcula como el máximo que pidan los plugins instalados —
    // en esta máquina eso resolvía a una versión ("25.0.3") que nunca se instaló, y el build
    // fallaba con un error sin detalle ("What went wrong: 25.0.3"). Se fija a mano la más
    // nueva instalada (28.2.13676358: el plugin jni la exige; los NDK son retrocompatibles).
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.globalappsuite.revendo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
