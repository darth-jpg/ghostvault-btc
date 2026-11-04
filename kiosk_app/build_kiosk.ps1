# GhostKiosk Build Script
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$srcDir = Join-Path $scriptDir "src\main"
$buildDir = Join-Path $scriptDir "build"

Remove-Item "$buildDir\obj" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$buildDir\gen" -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$buildDir\obj" -Force | Out-Null

$sdkDir = "C:\Android\sdk"
if (-not (Test-Path $sdkDir)) {
    $sdkDir = "$env:LOCALAPPDATA\Android\Sdk"
}
$buildToolsDir = Join-Path $sdkDir "build-tools\31.0.0"
$aapt2 = Join-Path $buildToolsDir "aapt2.exe"
$zipalign = Join-Path $buildToolsDir "zipalign.exe"
$d8Jar = Join-Path $buildToolsDir "lib\d8.jar"
$apksignerJar = Join-Path $buildToolsDir "lib\apksigner.jar"
$androidJar = Join-Path $sdkDir "platforms\android-31\android.jar"

$javaBin = Split-Path (Get-Command java.exe -ErrorAction SilentlyContinue).Source
if (-not $javaBin -or -not (Test-Path "$javaBin\javac.exe")) {
    $javaBin = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin"
}
$java = Join-Path $javaBin "java.exe"
$javac = Join-Path $javaBin "javac.exe"
$jar = Join-Path $javaBin "jar.exe"
$keytool = Join-Path $javaBin "keytool.exe"

# Generate local debug keystore if not present
$keystore = Join-Path $buildDir "debug.keystore"
if (-not (Test-Path $keystore)) {
    Write-Host "Generating ephemeral build keystore..." -ForegroundColor Yellow
    & $keytool -genkey -v -keystore $keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
}

Write-Host "Compiling Resources with aapt2..." -ForegroundColor Yellow
& $aapt2 compile --dir "$srcDir\res" -o "$buildDir\res.zip"
& $aapt2 link -I $androidJar --manifest "$srcDir\AndroidManifest.xml" -o "$buildDir\unaligned.apk" "$buildDir\res.zip" --java "$buildDir\gen"

Write-Host "Compiling Java with javac..." -ForegroundColor Yellow
$javaFiles = Get-ChildItem -Path "$srcDir\java\*.java", "$srcDir\java\com\ghostvault\kiosk\*.java" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
if (Test-Path "$buildDir\gen") {
    $genFiles = Get-ChildItem -Path "$buildDir\gen\*.java" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    if ($genFiles) { $javaFiles += $genFiles }
}

& $javac -encoding UTF-8 -source 8 -target 8 -cp $androidJar -d "$buildDir\obj" $javaFiles

Write-Host "DEXing with D8..." -ForegroundColor Yellow
$classFiles = Get-ChildItem -Path "$buildDir\obj" -Recurse -Filter "*.class" | Select-Object -ExpandProperty FullName
& $java -cp $d8Jar com.android.tools.r8.D8 --lib $androidJar --output "$buildDir" $classFiles

Write-Host "Packaging and Signing APK..." -ForegroundColor Yellow
Push-Location "$buildDir"
& $jar -uf "$buildDir\unaligned.apk" classes.dex
& $zipalign -f 4 "$buildDir\unaligned.apk" "$buildDir\GhostKiosk.apk"
& $java -jar $apksignerJar sign --ks $keystore --ks-pass pass:android --key-pass pass:android "$buildDir\GhostKiosk.apk"
Pop-Location

Write-Host "Build Complete! Output: $buildDir\GhostKiosk.apk" -ForegroundColor Green
