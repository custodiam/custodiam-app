import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar key.properties para firma (si existe)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val hasKeystore = keystorePropertiesFile.exists()

// Cargar secrets.properties para la API key de Google Maps (si existe).
// Lo genera `just secrets` desde secrets/maps.sops.env (sops+age) y está
// gitignored. Si falta, el placeholder queda vacío: el build no falla
// (CI web no necesita la key) pero el mapa nativo no cargaría.
val mapsSecretsFile = rootProject.file("secrets.properties")
val mapsSecrets = Properties()
if (mapsSecretsFile.exists()) {
    mapsSecretsFile.inputStream().use { mapsSecrets.load(it) }
}
val mapsApiKey: String = mapsSecrets.getProperty("MAPS_API_KEY") ?: ""

android {
    namespace = "es.custodiam.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Signing configs
    signingConfigs {
        if (hasKeystore) {
            getByName("debug") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    defaultConfig {
        applicationId = "es.custodiam.app"
        // google_maps_flutter exige Android SDK 24+. Tomamos el mayor
        // entre el default de Flutter y 24 para no bajarlo nunca.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inyecta la API key de Google Maps en el manifest sin hardcodearla
        // (el manifest commiteado solo lleva ${MAPS_API_KEY}).
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // Usa signing de release si key.properties existe, debug como fallback
            signingConfig = if (hasKeystore) {
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
