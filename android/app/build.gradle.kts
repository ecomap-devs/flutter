import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciais do keystore de release, vindas de android/key.properties.
//
// O arquivo esta no .gitignore. Sem ele, o build de RELEASE falha de
// proposito (veja o fim do arquivo). Ate 01/10/2026 ele caia no keystore de
// debug, que e publico e esta neste repositorio: qualquer pessoa conseguiria
// assinar um APK com a mesma identidade e instala-lo como "atualizacao" por
// cima do app de alguem. Quem so quer rodar o app usa o build de debug.
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
                // Relativo a android/, como o key.properties e escrito
                // ("keystore/release.jks"). Com `file()` o Gradle procurava em
                // android/app/ e o release com a chave de verdade nunca saia —
                // o que ficava escondido enquanto a falta de chave caia no debug.
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (temChaveDeRelease) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Release sem a chave de release nao sai: falha com a explicacao, em vez de
// sair assinado com a chave de debug publica.
tasks.configureEach {
    if (name in setOf("packageRelease", "bundleRelease", "signReleaseBundle")) {
        doFirst {
            if (!temChaveDeRelease) {
                throw GradleException(
                    "Build de release sem android/key.properties. A chave de " +
                        "debug e publica e nao pode assinar release. Para testar, " +
                        "use o build de debug (flutter build apk --debug)."
                )
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
