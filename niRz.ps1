$MINECRAFT = "$env:APPDATA\.minecraft"

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

function setup {
    $nirz_profile = get_profile
    if (-not $nirz_profile) {
        Write-Host "Installing profile 'niRz' into launcher."
        install_profile
        $nirz_profile = get_profile
    }
    update_launcher_profile $nirz_profile_raw
    $nirz_profile = get_profile
   
    # check if forge version installed
    $lastVersionId = $nirz_profile.lastVersionId
    if (-not (Test-Path "$MINECRAFT\versions\$lastVersionId")) {
        $installer_name = "$lastVersionId-installer.jar"
        $url = "https://github.com/dualcoding/mc/raw/main/forge/$installer_name"
        Write-Host "Downloading new forge version $lastVersionId from $url."
        iwr "https://github.com/dualcoding/mc/raw/main/forge/$installer_name" -OutFile "$MINECRAFT\niRz\tmp\$installer_name"
        cd "$MINECRAFT\niRz\tmp"
        start "$MINECRAFT\niRz\tmp\$installer_name" -Wait
    }

    # download override pack if not installed
    try {
        $niRz_installed_profile = Get-Content "$MINECRAFT\niRz\installs\niRz\niRz_profile.json" -ErrorAction Ignore |ConvertFrom-Json
    }
    catch {
        $niRz_installed_profile = @{}
    }
    $niRz_installed_version = $niRz_installed_profile.created
    if (-not $niRz_installed_version -eq $nirz_profile.created) {
        rm "$MINECRAFT\niRz\installs\niRz\mods\*.jar"
        $pack_name = "niRz"
        Write-Host "Downloading pack $pack_name"
        iwr "https://github.com/dualcoding/mc/raw/main/packs/$pack_name.zip" -OutFile "$MINECRAFT\niRz\tmp\$pack_name.zip"
        Expand-Archive "$MINECRAFT\niRz\tmp\$pack_name.zip" -DestinationPath "$MINECRAFT\niRz\installs\niRz" -Force
    }



}
setup

start "C:\Program Files\WindowsApps\Microsoft.4297127D64EC6_1.1.17.0_x64__8wekyb3d8bbwe\Minecraft.exe"


#* this file should be saved as "UTF8 with BOM" -- !! check what happens with github/iwr
#*? multiple pack overlays?