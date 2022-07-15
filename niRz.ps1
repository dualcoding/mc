$MINECRAFT = "$env:APPDATA\.minecraft"


# = PROFILES = #

$nirz_profile_raw = @"
    "niRz" : {
      "created" : "2022-01-15T12:00:00.000Z",
      "gameDir" : "$($MINECRAFT.Replace('\','\\'))\\niRz\\installs\\niRz",
      "icon" : "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAMjSURBVHhe7VvNbtNAEJ5xYkdN4jRSmhyK4AiIV+FU4IgQFx4AiQeqhMQRIdQbL8GJFwCpSIgWknCIndjMOGOROrvrUIPUdvazRp+9f579vPHMKglOJpMcGiBJEshz+xBRFAEiytW/R9396xAIq4UXQFgtvADCauEF4BDispsO3N/ft86S43cYhs44fqPzAA0rwL8DhNXCCyCsFl4AYbXwAgirhRdAWC28AMJqgb2459gN0m6uQ7u5gE4srZJFAllmruRd4F5nr9FucJWveFcmVxfBpenSvRvMMzmxAO/demDvDQjtRUijWCaAOayilKpNQyA5mMF0eQ6ZwwuX84gBjLsTaAXtLf3ZI+6b/EwhW1nGoEZBl5jXua3Jp1dn5ip+6AuAH8cI2XR9fQHcqw0wfJZD64DOK3Nk538lc3j+/iGczj4XkzDBtp9n0fpRDG+efIDDwW1YZbQSNsH+UNH0LT2EMzqvfphpSIwABo+pKl5fmxD0owHdyG49iKFL1ssrJmX9kNp1tvvFBccQkBCXB0I36hfjGC0kQ/aR7mUz9sPgX2kBK+00OngpWw9Tnw2zCL8zch6DVohp7OIgbuKfD4PCauEFaGELnEZHYLGiztRHjOuqweNvwH35JRpQHmEbv7ANn6pm6rdp+PHlV/N7qgyDrynMUBjcymW4F4fBp+TciM4rYZAdnyczeHFyBKfzL8XNTEhTyiMcYfD40QkcxuYwyDnS7B35d06XlbXMQxZh8AjXYdCSiuDdO/ftL2qqWczIQUumx+jEIWDL9JwpEaJJfJ9/K5y3ZYPuRAjhoD+WRMjcLiH/7JkoZbJ9zmSlwAAcjUd2D6gmkVTTtAC4LAyjYokaB6HC5XK5bnxJtENaZmbtCqQppeIO/yLyb3v5/kHtL0SafvPT9JubpuPX9fdRQFgtvADCauEFEFYLL4CwWngBhNXCCyCsFo1/J1i2qfYr7aoDh8Oh08tdJuHabTUV4b/vBssnZbNdYOpX2lWHfwcIq4UXQFgtvADCalErAP9fgGOpzVwx9jqgVgCeoMuuO/xHQFgtvADCauEFEFYKgN8B2/f69dQRawAAAABJRU5ErkJggg==",
      "lastVersionId" : "1.18.1-forge-39.1.0",
      "name" : "niRz",
      "type" : "custom"
    }
"@

function get_profile {
    $launcher_profiles = Get-Content -Raw "$MINECRAFT\launcher_profiles.json" | ConvertFrom-Json
    if (-not $launcher_profiles.profiles.niRz) {
        return $false;
    }

    return $launcher_profiles.profiles.niRz
}
function add_launcher_profile ($raw_profile) {
    $inclusion_site = @"
    }
  },
  "settings" : {
"@

    $inclusion_site_edited = @"
    },
$raw_profile
  },
  "settings" : {
"@

    $launcher_profiles_content = Get-Content -Raw "$MINECRAFT\launcher_profiles.json" -Encoding UTF8
    $launcher_profiles_new = $launcher_profiles_content -replace $inclusion_site,$inclusion_site_edited

    # avoid BOM nonsense
    $utf8 = New-Object System.Text.UTF8Encoding $false
    Set-Content -Encoding Byte -Path "$MINECRAFT\launcher_profiles.json" -Value $utf8.GetBytes($launcher_profiles_new)
}
function update_launcher_profile ($raw_profile) {
    $launcher_profiles_content = Get-Content -Raw "$MINECRAFT\launcher_profiles.json"
    $launcher_profiles_new = $launcher_profiles_content -replace '(?ms)    "niRz" : {[^}]*}',$nirz_profile_raw
    
    # avoid BOM nonsense
    $utf8 = New-Object System.Text.UTF8Encoding $false
    Set-Content -Encoding Byte -Path "$MINECRAFT\launcher_profiles.json" -Value $utf8.GetBytes($launcher_profiles_new)

}

function install_profile {
    mkdir "$MINECRAFT\niRz\installs\niRz" -ErrorAction SilentlyContinue
    mkdir "$MINECRAFT\niRz\tmp" -ErrorAction SilentlyContinue
    add_launcher_profile $nirz_profile_raw
}


# = FORGE =#

function forge_is_installed($versionId) {
    return (Test-Path "$MINECRAFT\versions\$versionId");
}

function forge_launch_installer($installer_path) {

    # try launching installer using minecraft java
    $minecraft_java = "$env:LOCALAPPDATA\Packages\Microsoft.4297127D64EC6_8wekyb3d8bbwe\LocalCache\Local\runtime\java-runtime-beta\windows-x64\java-runtime-beta\bin\javaw.exe"
    if (Test-Path $minecraft_java) {
        Write-Host  "... launching forge installer using Minecraft java."
        Start-Process -Wait -FilePath "$minecraft_java" -ArgumentList @("-jar $installer_name") -WorkingDirectory "$MINECRAFT\niRz\tmp"
    }

    # try launching installer using global java
    elseif (Get-Command "javaw" -ErrorAction Ignore) {
        Write-Warning "Could not find Minecraft java."
        Write-Host    "... launching forge installer using java in path."
        Start-Process -Wait -FilePath "javaw"           -ArgumentList @("-jar $installer_name") -WorkingDirectory "$MINECRAFT\niRz\tmp"
    }

    # failure
    else {
        throw "Java is not installed, cannot launch forge installer."
    }

}

function forge_install ($versionId, [bool]$Force = $false) {
    $installer_name = "$versionId-installer.jar"
    $installer_path = "$MINECRAFT\niRz\tmp\$installer_name"
    $installer_url = "https://github.com/dualcoding/mc/raw/main/forge/$installer_name"

    # check if forge version is installed already
    if (-not ($Force) -and (forge_is_installed($versionId))) {
        Write-Verbose "Skipping install of Forge version '$versionId' since it's already installed."
        return;
    }

    Write-Host "Installing new Forge version '$versionId'."

    Write-Host "... downloading Forge installer $installer_url."
    Invoke-WebRequest $installer_url -OutFile $installer_path

    # launch forge installer (player needs to click "ok")
    forge_launch_installer($installer_path)

    # abort if Forge is still not installed (eg: aborted by user or installer error)
    if (-not (forge_is_installed($versionId))) {
        throw "Forge install failed."
    }
}


#= MAIN =#

function setup {
    $nirz_profile = get_profile
    if (-not $nirz_profile) {
        Write-Host "Installing profile 'niRz' into launcher."
        install_profile
        $nirz_profile = get_profile
    }
    update_launcher_profile $nirz_profile_raw
    $nirz_profile = get_profile
   
    # check if forge version is installed, otherwise download and launch forge installer
    $lastVersionId = $nirz_profile.lastVersionId
    forge_install $lastVersionId

    # copy options from .minecraft if missing (new install)
    if (-not (Test-Path "$MINECRAFT\niRz\installs\niRz\options.txt")) {
        Copy-Item -Path "$MINECRAFT\options.txt" -Destination "$MINECRAFT\niRz\installs\niRz\options.txt" -ErrorAction Ignore
    }
    # copy OptiFine options if missing (ignore if not present)
    if (-not (Test-Path "$MINECRAFT\niRz\installs\niRz\optionsof.txt")) {
        Copy-Item -Path "$MINECRAFT\optionsof.txt" -Destination "$MINECRAFT\niRz\installs\niRz\options.txt" -ErrorAction Ignore
    }
    # if (-not (Test-Path "$MINECRAFT\niRz\installs\niRz\optionsshaders.txt")) {
    #     Copy-Item -Path "$MINECRAFT\optionsshaders.txt" -Destination "$MINECRAFT\niRz\installs\niRz\optionsshaders.txt" -ErrorAction Ignore
    # }

    # download override pack if not installed
    try {
        $niRz_installed_profile = Get-Content "$MINECRAFT\niRz\installs\niRz\niRz_profile.json" -ErrorAction Ignore |ConvertFrom-Json
    }
    catch {
        $niRz_installed_profile = @{}
    }
    $niRz_installed_version = $niRz_installed_profile.created
    if (-not $niRz_installed_version -eq $nirz_profile.created) {
        if (Test-Path "$MINECRAFT\niRz\installs\niRz\mods" -PathType Container) {
            Remove-Item "$MINECRAFT\niRz\installs\niRz\mods\*.jar"
        }
        $pack_name = "niRz"
        Write-Host "Downloading pack $pack_name"
        Invoke-WebRequest "https://github.com/dualcoding/mc/raw/main/packs/$pack_name.zip" -OutFile "$MINECRAFT\niRz\tmp\$pack_name.zip"
        Expand-Archive "$MINECRAFT\niRz\tmp\$pack_name.zip" -DestinationPath "$MINECRAFT\niRz\installs\niRz" -Force
    }

}


# Quit if anything goes wrong
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

setup
Start-Process "C:\Program Files\WindowsApps\Microsoft.4297127D64EC6_1.1.17.0_x64__8wekyb3d8bbwe\Minecraft.exe"

# Reset $ErrorActionPreference to original value
$ErrorActionPreference = $oldErrorActionPreference