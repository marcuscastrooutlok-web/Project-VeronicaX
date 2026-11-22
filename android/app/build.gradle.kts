plugins {
    id("com.android.application")
}

android {
    namespace = "org.veronicax.android"
    compileSdk = 35
    ndkVersion = "27.2.12479018"

    defaultConfig {
        applicationId = "org.veronicax.android"
        minSdk = 28
        targetSdk = 32
        versionCode = 1
        versionName = "0.1.0"
        ndk { abiFilters += "arm64-v8a" }
        externalNativeBuild {
            cmake {
                arguments += listOf(
                    "-DANDROID_STL=c++_shared",
                    "-DREX_PROJECT_ROOT=${rootProject.projectDir.parentFile.absolutePath}"
                )
                cppFlags += listOf("-std=c++23")
            }
        }
    }
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.31.1"
        }
    }
    buildTypes {
        release { isMinifyEnabled = false }
        debug { isJniDebuggable = true }
    }
    packaging { jniLibs { useLegacyPackaging = true } }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
