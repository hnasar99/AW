plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val supportedTargetAbis = mapOf(
    "android-arm64" to "arm64-v8a",
    "android-x64" to "x86_64",
)
val requestedAbis = providers.gradleProperty("target-platform")
    .orElse("android-arm64")
    .get()
    .split(',')
    .map { target ->
        supportedTargetAbis[target.trim()]
            ?: error("Unsupported Android target '$target'; use android-arm64 or android-x64.")
    }
    .toSet()
val splitPerAbi = providers.gradleProperty("split-per-abi")
    .map { it.toBoolean() }
    .getOrElse(false)

val signingPath = System.getenv("AW_KEYSTORE_PATH")
val signingPassword = System.getenv("AW_KEYSTORE_PASSWORD")
val signingAlias = System.getenv("AW_KEY_ALIAS")
val signingKeyPassword = System.getenv("AW_KEY_PASSWORD")
val signingReady = listOf(signingPath, signingPassword, signingAlias, signingKeyPassword)
    .all { !it.isNullOrBlank() }

android {
    namespace = "io.fluuix.arc_wallet_flutter"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.fluuix.aw"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Flutter 3.47.7 sets three defaults during plugin apply(), before
            // this block. Replace them so dependency JNI libraries cannot make
            // the APK advertise an ABI without Flutter AOT and the Rust bridge.
            abiFilters.clear()
            // With splits, Flutter already selects these target-platform ABIs;
            // AGP rejects using ndk.abiFilters and ABI splits simultaneously.
            if (!splitPerAbi) abiFilters.addAll(requestedAbis)
        }
    }

    signingConfigs {
        if (signingReady) {
            create("operatorRelease") {
                storeFile = file(signingPath!!)
                storePassword = signingPassword
                keyAlias = signingAlias
                keyPassword = signingKeyPassword
            }
        }
    }
    flavorDimensions += "distribution"
    productFlavors {
        create("qa") {
            dimension = "distribution"
            applicationIdSuffix = ".qa"
            versionNameSuffix = "-qa"
            signingConfig = signingConfigs.getByName("debug")
        }
        create("production") {
            dimension = "distribution"
            if (signingReady) signingConfig = signingConfigs.getByName("operatorRelease")
        }
    }
    buildTypes {
        release {
            // QA uses its own app ID. A production build never silently uses a debug key.
            signingConfig = null
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
    packaging {
        jniLibs {
            // Their Rust implementations are linked into the bridge. Neither
            // auxiliary cargo-ndk product is a DT_NEEDED dependency; also reject
            // legacy copies left in a previous native staging directory.
            excludes += setOf("**/libtinymcp.so", "**/libtinyconnectors.so")
        }
    }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Production", true) && it.name.contains("Release", true) }) {
        require(signingReady && file(signingPath!!).isFile) {
            "Production signing requires AW_KEYSTORE_PATH, AW_KEYSTORE_PASSWORD, AW_KEY_ALIAS and AW_KEY_PASSWORD."
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
