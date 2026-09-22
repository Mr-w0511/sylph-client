allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 必须在 evaluationDependsOn 之前注册：强制所有 Android library 插件模块（如 file_picker）
// 以 compileSdk 36 编译，解决 flutter_plugin_android_lifecycle 要求 compileSdk >= 36 的校验失败
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                if ((compileSdk ?: 0) < 36) {
                    compileSdk = 36
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
