# ==============================================================================
# AlphaCloudSync Module: Providers/Provider.Registry
# Extensible Multi-Cloud Provider Contract (Google Drive v1.0; OneDrive/Dropbox/S3 ready for v1.1+)
# ==============================================================================

$script:CloudProviders = [ordered]@{}

function Register-CloudProvider {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$DisplayName,
        [Parameter(Mandatory=$true)][string]$RcloneType,
        [string]$DefaultRemotePrefix = "cloud",
        [bool]$SupportsQuota = $true,
        [bool]$SupportsTrash = $true,
        [bool]$SupportsMyComputerScope = $false,
        [bool]$SupportsUnifiedCombine = $true,
        [string]$AuthFunction = "",
        [string]$IdentityFunction = "",
        [string]$ListRemotesFunction = ""
    )
    $key = $Id.Trim().ToLowerInvariant()
    $script:CloudProviders[$key] = [PSCustomObject]@{
        Id                      = $key
        DisplayName             = $DisplayName
        RcloneType              = $RcloneType.Trim().ToLowerInvariant()
        DefaultRemotePrefix     = $DefaultRemotePrefix
        SupportsQuota           = $SupportsQuota
        SupportsTrash           = $SupportsTrash
        SupportsMyComputerScope = $SupportsMyComputerScope
        SupportsUnifiedCombine  = $SupportsUnifiedCombine
        AuthFunction            = $AuthFunction
        IdentityFunction        = $IdentityFunction
        ListRemotesFunction     = $ListRemotesFunction
    }
}

function Get-CloudProvider {
    param([string]$Id = "drive")
    if ([string]::IsNullOrWhiteSpace($Id)) { $Id = "drive" }
    $key = $Id.Trim().ToLowerInvariant()
    if ($script:CloudProviders.Contains($key)) { return $script:CloudProviders[$key] }
    return $null
}

function Get-RegisteredCloudProviders {
    return @($script:CloudProviders.Values)
}

function Get-ConfiguredCloudRemotes {
    $res = Invoke-RcloneCapture -Arguments "config dump --quiet" -TimeoutMs 10000
    if ($res.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($res.StdOut)) { return @() }
    try {
        $supportedTypes = @($script:CloudProviders.Values | ForEach-Object { $_.RcloneType } | Sort-Object -Unique)
        $dump = $res.StdOut | ConvertFrom-Json
        $list = @()
        foreach ($prop in $dump.PSObject.Properties) {
            $rType = if ($prop.Value -and $prop.Value.PSObject.Properties["type"]) { ([string]$prop.Value.type).ToLowerInvariant() } else { "" }
            if ($supportedTypes -contains $rType) {
                $list += [PSCustomObject]@{ Name = $prop.Name; RcloneType = $rType }
            }
        }
        return $list
    } catch { return @() }
}

function Get-ProviderForRemote {
    param([string]$TargetRemote)
    if ([string]::IsNullOrWhiteSpace($TargetRemote)) { return (Get-CloudProvider -Id "drive") }
    $match = @(Get-ConfiguredCloudRemotes | Where-Object { $_.Name -eq $TargetRemote } | Select-Object -First 1)
    if ($match.Count -gt 0) {
        $found = @($script:CloudProviders.Values | Where-Object { $_.RcloneType -eq $match[0].RcloneType } | Select-Object -First 1)
        if ($found.Count -gt 0) { return $found[0] }
    }
    return (Get-CloudProvider -Id "drive")
}
