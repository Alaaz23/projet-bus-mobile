# ============================================================
# Script : launch_emulator.ps1
# Description : Vérifie l'environnement Flutter/Android et
#               lance l'émulateur + l'application Flutter
# ============================================================

Write-Host "=== Vérification de Flutter ===" -ForegroundColor Cyan

# Vérifier si Flutter est disponible
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "[ERREUR] Flutter n'est pas trouvé dans le PATH." -ForegroundColor Red
    Write-Host "  → Installez Flutter depuis : https://docs.flutter.dev/get-started/install/windows"
    Write-Host "  → Puis ajoutez C:\flutter\bin au PATH système."
    exit 1
}

Write-Host "[OK] Flutter trouvé : $(flutter --version | Select-Object -First 1)" -ForegroundColor Green

# Vérifier les émulateurs disponibles
Write-Host "`n=== Émulateurs disponibles ===" -ForegroundColor Cyan
$emulators = flutter emulators 2>&1
Write-Host $emulators

if ($emulators -match "No emulators available") {
    Write-Host "`n[INFO] Aucun émulateur configuré." -ForegroundColor Yellow
    Write-Host "  → Ouvrez Android Studio → Tools → Device Manager → Create Device"
    Write-Host "  → Ou créez-en un via la commande : flutter emulators --create --name Pixel6"

    # Tentative de création automatique d'un émulateur par défaut
    Write-Host "`n[INFO] Tentative de création d'un émulateur Pixel 6 (API 34)..." -ForegroundColor Yellow
    $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
    $avdManager = "$sdkPath\cmdline-tools\latest\bin\avdmanager.bat"

    if (Test-Path $avdManager) {
        & $avdManager create avd -n "Pixel6_API34" -k "system-images;android-34;google_apis;x86_64" -d "pixel_6" --force
        Write-Host "[OK] Émulateur 'Pixel6_API34' créé." -ForegroundColor Green
    } else {
        Write-Host "[ERREUR] avdmanager non trouvé. Installez Android Studio d'abord." -ForegroundColor Red
        exit 1
    }
}

# Sélectionner le premier émulateur disponible
$emulatorName = (flutter emulators 2>&1 | Select-String "•" | Select-Object -First 1) -replace ".*•\s*", "" -replace "\s.*", ""

if (-not $emulatorName) {
    Write-Host "[ERREUR] Impossible de détecter un émulateur." -ForegroundColor Red
    exit 1
}

Write-Host "`n[INFO] Lancement de l'émulateur : $emulatorName" -ForegroundColor Cyan
Start-Process -NoNewWindow flutter -ArgumentList "emulators --launch $emulatorName"

# Attendre que l'émulateur soit prêt
Write-Host "[INFO] Attente du démarrage de l'émulateur (60 secondes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Vérifier que le device est bien connecté
Write-Host "`n=== Appareils connectés ===" -ForegroundColor Cyan
flutter devices

# Lancer l'application
Write-Host "`n=== Compilation et lancement de l'application ===" -ForegroundColor Cyan
Set-Location $PSScriptRoot
flutter run


