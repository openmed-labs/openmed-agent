param(
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

$Repo = if ($env:OPENMED_INSTALL_REPO) { $env:OPENMED_INSTALL_REPO } elseif ($env:OPENMED_RELEASE_REPO) { $env:OPENMED_RELEASE_REPO } else { "openmed-labs/openmed-agents" }
$InstallDir = if ($env:OPENMED_INSTALL_DIR) { $env:OPENMED_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "OpenMed\bin" }
$ReleaseBaseUrl = if ($env:OPENMED_RELEASE_BASE_URL) { ($env:OPENMED_RELEASE_BASE_URL).TrimEnd([char]"/") } else { "" }
$script:TelemetryEndpoint = ""
$script:TelemetryTarget = ""
$script:TelemetryRequestedVersion = $Version
$script:TelemetryResolvedVersion = ""
$script:TelemetryReleaseSlug = ""
$script:TelemetryArtifact = ""

function Normalize-VersionTag {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq "latest" -or $Value -eq "stable") {
        return ""
    }
    if ($Value.StartsWith("v")) {
        return $Value
    }
    return "v$Value"
}

function Get-Target {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString().ToLowerInvariant()
    switch ($arch) {
        "x64" { return "windows-x64" }
        "arm64" { return "windows-arm64" }
        default { throw "Unsupported architecture: $arch" }
    }
}

function Get-ReleaseBaseUrl {
    param([string]$RequestedVersion)

    if (-not [string]::IsNullOrWhiteSpace($ReleaseBaseUrl)) {
        return $ReleaseBaseUrl
    }

    $tag = Normalize-VersionTag $RequestedVersion
    if ([string]::IsNullOrWhiteSpace($tag)) {
        return "https://github.com/$Repo/releases/latest/download"
    }
    return "https://github.com/$Repo/releases/download/$tag"
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath
    )

    Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
}

function Download-Json {
    param([string]$Url)

    return Invoke-RestMethod -Uri $Url
}

function Get-TelemetryEndpoint {
    param([string]$BaseUrl)

    if ($BaseUrl -match "^(?<origin>https?://.+?)/r/[^/]+$") {
        return "$($Matches.origin)/v1/install-events"
    }
    return ""
}

function Get-TelemetryReleaseSlug {
    param([string]$BaseUrl)

    if ($BaseUrl -match "^https?://.+?/r/(?<slug>[^/]+)$") {
        return $Matches.slug
    }
    return ""
}

function Test-TelemetrySafeValue {
    param([string]$Value)

    return $Value -match "^[A-Za-z0-9._+-]+$"
}

function Get-TelemetrySafeValue {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }
    if (Test-TelemetrySafeValue $Value) {
        return $Value
    }
    return ""
}

function Send-InstallTelemetry {
    param([string]$EventType)

    if ([string]::IsNullOrWhiteSpace($script:TelemetryEndpoint)) {
        return
    }

    try {
        $payload = @{
            event_type = $EventType
            installer = "install.ps1"
            platform_family = "windows"
            target = Get-TelemetrySafeValue $script:TelemetryTarget
            requested_version = Get-TelemetrySafeValue $script:TelemetryRequestedVersion
            resolved_version = Get-TelemetrySafeValue $script:TelemetryResolvedVersion
            release_slug = Get-TelemetrySafeValue $script:TelemetryReleaseSlug
            artifact = Get-TelemetrySafeValue $script:TelemetryArtifact
        } | ConvertTo-Json -Compress

        Invoke-RestMethod `
            -Uri $script:TelemetryEndpoint `
            -Method Post `
            -ContentType "application/json" `
            -Body $payload `
            -TimeoutSec 2 | Out-Null
    }
    catch {
        return
    }
}

function Path-ContainsInstallDir {
    $parts = ($env:PATH -split ";") | ForEach-Object { $_.TrimEnd([char]"\") }
    return $parts -contains $InstallDir.TrimEnd([char]"\")
}

function Test-Sha256 {
    param([string]$Value)

    return $Value -match "^[0-9a-fA-F]{64}$"
}

function Test-ReleaseComponent {
    param([string]$Value)

    return $Value -match "^[A-Za-z0-9][A-Za-z0-9._+-]*$"
}

function Test-PositiveSize {
    param([string]$Value)

    return $Value -match "^[1-9][0-9]*$"
}

function Verify-AuthenticodeSignature {
    param([string]$Path)

    $signature = Get-AuthenticodeSignature -FilePath $Path
    if ($signature.Status -ne "Valid") {
        throw "Authenticode signature verification failed for $Path`: $($signature.Status)"
    }
    Write-Host "Windows Authenticode signature verified."
}

function Main {
    $target = Get-Target
    $baseUrl = Get-ReleaseBaseUrl $Version
    $manifestUrl = "$baseUrl/openmed-manifest.json"
    $script:TelemetryTarget = $target
    $script:TelemetryEndpoint = Get-TelemetryEndpoint $baseUrl
    $script:TelemetryReleaseSlug = Get-TelemetryReleaseSlug $baseUrl

    Write-Host "Resolving OpenMed release for $target..."
    $manifest = Download-Json $manifestUrl
    $assetProperty = $manifest.assets.PSObject.Properties[$target]
    if ($null -eq $assetProperty) {
        throw "No release asset found for target $target."
    }
    $asset = $assetProperty.Value

    $archiveName = [string]$asset.archive
    $binaryName = [string]$asset.binary
    $expectedSha = [string]$asset.sha256
    $expectedSize = [string]$asset.size
    $releaseVersion = [string]$manifest.version

    if ([string]::IsNullOrWhiteSpace($archiveName) -or [string]::IsNullOrWhiteSpace($expectedSha) -or [string]::IsNullOrWhiteSpace($expectedSize)) {
        throw "Manifest is missing archive, checksum, or size for target $target."
    }
    if ([string]::IsNullOrWhiteSpace($releaseVersion)) {
        throw "Manifest is missing version."
    }
    if (-not (Test-ReleaseComponent $releaseVersion)) {
        throw "Release manifest has invalid version: $releaseVersion"
    }
    if (-not (Test-ReleaseComponent $target)) {
        throw "Release manifest has invalid target: $target"
    }
    $expectedArchiveName = "openmed-$releaseVersion-$target.tar.gz"
    if ($archiveName -ne $expectedArchiveName) {
        throw "Release manifest has invalid archive name for $target`: $archiveName"
    }
    if (-not (Test-Sha256 $expectedSha)) {
        throw "Release manifest has invalid sha256 checksum."
    }
    if (-not (Test-PositiveSize $expectedSize)) {
        throw "Release manifest has invalid archive size."
    }
    [int64]$expectedSizeBytes = [int64]::Parse($expectedSize, [System.Globalization.CultureInfo]::InvariantCulture)

    $expectedBinaryName = "openmed.exe"
    if ([string]::IsNullOrWhiteSpace($binaryName)) {
        $binaryName = $expectedBinaryName
    }
    if ($binaryName -ne $expectedBinaryName) {
        throw "Release manifest has invalid binary name for $target`: $binaryName"
    }
    $script:TelemetryResolvedVersion = $releaseVersion
    $script:TelemetryArtifact = $archiveName
    Send-InstallTelemetry "install_resolved"

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString("N"))
    $extractDir = Join-Path $tmpDir "extract"
    New-Item -ItemType Directory -Force -Path $extractDir, $InstallDir | Out-Null

    try {
        $archivePath = Join-Path $tmpDir $archiveName
        Download-File "$baseUrl/$archiveName" $archivePath

        $actualSizeBytes = (Get-Item $archivePath).Length
        if ($actualSizeBytes -ne $expectedSizeBytes) {
            throw "Size verification failed for $archiveName`: expected $expectedSizeBytes, got $actualSizeBytes."
        }

        $actualSha = (Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash.ToLowerInvariant()
        if ($actualSha -ne $expectedSha.ToLowerInvariant()) {
            throw "Checksum verification failed for $archiveName."
        }

        $archiveMembers = @(tar -tzf $archivePath)
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to inspect release archive $archiveName."
        }
        if ($archiveMembers.Count -ne 1 -or $archiveMembers[0] -ne $expectedBinaryName) {
            throw "Release archive must contain exactly $expectedBinaryName."
        }

        tar -xzf $archivePath -C $extractDir $expectedBinaryName
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to extract release archive $archiveName."
        }

        $extractedBinaryPath = Join-Path $extractDir $expectedBinaryName
        Verify-AuthenticodeSignature $extractedBinaryPath

        $installedPath = Join-Path $InstallDir $expectedBinaryName
        Copy-Item -Force $extractedBinaryPath $installedPath

        Write-Host "Installed OpenMed $releaseVersion to $installedPath"
        & $installedPath --version
        Send-InstallTelemetry "install_success"

        if (-not (Path-ContainsInstallDir)) {
            Write-Host ""
            Write-Host "Add $InstallDir to your PATH for future shells:"
            Write-Host "  setx PATH `"$env:PATH;$InstallDir`""
        }
    }
    finally {
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    }
}

try {
    Main
}
catch {
    Send-InstallTelemetry "install_failure"
    throw
}
