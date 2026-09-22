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
subprojects {
    project.evaluationDependsOn(":app")

    // Gradle 9 classpath-isolation workaround: CameraX
    // (androidx.camera:camera-core, pulled in transitively by the
    // camera_android_camerax plugin via mobile_scanner) declares its
    // androidx.concurrent:futures dependency in "runtime" scope. Under
    // Gradle 9 the compile classpath no longer gets runtime deps, which
    // breaks javac in :camera_android_camerax:compileDebugJavaWithJavac
    // with: "class file for androidx.concurrent.futures.CallbackToFutureAdapter
    // not found". Explicitly adding it to each subproject's implementation
    // configuration restores the class. It is already bundled transitively,
    // so nothing extra is introduced.
    plugins.withId("com.android.library") {
        dependencies {
            add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
