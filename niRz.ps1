# TODO: install/update powershell? MSI + Windows Update? (https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2)

function Install_Scoop {
    try {
        $_ = Get-Command scoop;
        # Write-Host "scoop is installed."
    }
    catch {
        Write-Host "Installing scoop."
        if ((Get-ExecutionPolicy -Scope CurrentUser) -eq 'Undefined') {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
        }
        irm get.scoop.sh | iex
    }
}

function Install_Ferium {
    try {
        $_ = Get-Command ferium;
        # Write-Host "ferium is installed."
    }
    catch {
        Write-Host "Installing ferium."
        scoop bucket add games
        scoop install ferium
    }
}

function Update_Ferium {
    $last_update = (scoop bucket list |where Name -eq 'games').Updated
    $time_since_last_update = (Get-Date) - $last_update
    #Write-Host "Time since last ferium update: $($time_since_last_update.Days) days."
    if ($time_since_last_update.Days -ge 7) {
        Write-Host "Updating ferium."
        scoop update
        scoop update ferium
    }
}

function Setup_Ferium {
    Install_Scoop
    Install_Ferium
    Update_Ferium
}
Setup_Ferium



function Install_Modpack {
}
