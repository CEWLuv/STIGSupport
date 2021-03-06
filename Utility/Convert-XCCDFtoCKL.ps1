﻿<#
.SYNOPSIS
    Converts a SCAP XCCDF File to a CKL file

.DESCRIPTION
    Loads a set of XCCDF files and saves them as checklists in the format of a given a template file

.PARAMETER TemplateCKLPath
    Full path to the CKL file. This file should be blank, or only contain answers that are not included in the XCCDF file

.PARAMETER STIGName
    A filter applied to the XCCDF files. This allows you to select a specific subset of a set of XCCDF files. For example U_WindowsServer_2012

.PARAMETER XCCDFPath
    Path to a folder containing the XCCDF files to convert. Will automatically be set to the user's profile\scc\results\scap directory (Default SCAP Directory)

.PARAMETER SaveDirectory
    Path to a folder to save the new CKL files
  
.EXAMPLE
    "Convert-XCCDFtoCKL.ps1" -TemplateCKLPath 'C:\CKLs\MyTemplate.ckl' -STIGName 'U_WINDOWS_SERVER_2012_R2' -XCCDFPath 'C:\Users\John.Doe\SCC\Results\SCAP' -SaveDirectory 'C:\Users\John.Doe\Scap Results\'
#>
Param([Parameter(Mandatory=$true)][ValidateScript({Test-Path -Path $_})][string]$TemplateCKLPath, 
    [Parameter(Mandatory=$true)][string]$STIGName, 
    [ValidateScript({Test-Path -Path $_})][string]$XCCDFPath=(Join-Path -Path $env:USERPROFILE -ChildPath "\SCC\Results\SCAP\"), 
    [Parameter(Mandatory=$true)][ValidateScript({Test-Path -Path $_})][string]$SaveDirectory
)

#Check if module imported
if ((Get-Module|Where-Object -FilterScript {$_.Name -eq "StigSupport"}).Count -le 0)
{
    #End if not
    Write-Error "Please import StigSupport.psm1 before running this script"
    return
}

#Grab a list of XCCDF files to convert to CKLs
$XMLFiles = Get-ChildItem -Path $XCCDFPath -Recurse -Filter "*XCCDF*$STIGName*.xml"

Write-Progress -Activity "Converting" -PercentComplete 0
$I=0;
#Loop through them
foreach ($File in $XMLFiles)
{
    #Load CKL, Load XCCDF, Fill CKL based on XCCDF, then save to a new CKL with name of [machinename]_[stigname].ckl
    $CKL = Import-StigCKL -Path $TemplateCKLPath
    $XCCDF = Import-XCCDF -Path $File.FullName
    Merge-XCCDFToCKL -CKLData $CKL -XCCDF $XCCDF
    $MachineInfo = Get-XCCDFHostData -XCCDF $XCCDF
    Export-StigCKL -Path (Join-Path -Path $SaveDirectory -ChildPath "$($MachineInfo.HostName)_$STIGName.ckl") -XMLData $CKL
    $I++
    Write-Progress -Activity "Converting" -PercentComplete (($I*100)/$XMLFiles.Count)
}
Write-Progress -Activity "Converting" -PercentComplete 100 -Completed