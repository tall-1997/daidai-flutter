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

gradle.beforeProject {
    extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.let {
        it.compileSdk = 36
    }
    extensions.findByType<com.android.build.api.dsl.ApplicationExtension>()?.let {
        it.compileSdk = 36
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
