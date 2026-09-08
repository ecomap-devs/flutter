import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciais do keystore de release, vindas de android/key.properties.
//
// O arquivo esta no .gitignore. Sem ele o build de release continua
// funcionando: cai no keystore de debug, como era antes. Isso e proposital —
// quem so quer rodar o app nao precisa ter a chave de publicacao.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val temChaveDeRelease = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "br.com.ecomapbrasil.ecomapbrasil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.ecomapbrasil.ecomapbrasil"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Keystore de debug COMPARTILHADO, versionado em android/keystore.
        //
        // Sem ele, cada pessoa do grupo assinaria com o proprio
        // ~/.android/debug.keystore, e cada um teria um SHA-1 diferente. Como a
        // chave de API do Firebase e restrita por package + SHA-1, o login
        // quebraria para quem nao estivesse na lista — e quebraria em silencio,
        // aparecendo como erro generico de autenticacao.
        //
        // Keystore de debug nao e segredo: assina apenas build de
        // desenvolvimento, nao publica nada, e a senha `android` e a convencao
        // documentada pelo proprio Android.
        getByName("debug") {
            storeFile = file("../keystore/debug.jks")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }

        if (temChaveDeRelease) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temChaveDeRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
