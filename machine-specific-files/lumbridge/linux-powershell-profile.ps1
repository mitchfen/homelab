$ErrorActionPreference = 'Stop'
$ProgressPreference="SilentlyContinue"

Set-Alias vim nvim
Set-Alias k kubectl

function Get-RunningDaemons { systemctl list-units --type=service --state=running }

function Add-PathVariable {
    param (
        [string]$addPath
    )
    if (Test-Path $addPath){
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env:PATH -split ':' | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $env:PATH = ($arrPath + $addPath) -join ':'
    } else {
        throw "'$addPath' is not a valid path."
    }
}

function Start-NixRebuild {
  sudo nixos-rebuild switch --upgrade
}

function Start-NixGarbageCollect {
  sudo nix-collect-garbage -d
}

function Edit-NixConfig {
  sudo nvim "/etc/nixos/configuration.nix"
}

function Get-NixGenerations {
  sudo nixos-rebuild list-generations
}

function Prompt {
  $reset = "`e[0m"
  $cyan = "`e[36m"
  $pink = "`e[38;5;205m"
  $green = "`e[32m"

  $currentDirectory = Get-Location
  $dateTime = Get-Date -Format "HH:mm:ss"
  $lastExitCode = $?
  $hostname = hostname

  try {
      $branch = $(git rev-parse --abbrev-ref HEAD).Trim()
      $branchInfo = " | $cyan$branch$reset"
  } catch {
      $branchInfo = ""
  }

  $prompt = "$green$dateTime$reset | $hostname | $pink$currentDirectory$reset$branchInfo $ "
  return $prompt
}

