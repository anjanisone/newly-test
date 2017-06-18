##-----------------------------------------------------------------------
## <copyright file="ApplyVersionToNuspec.ps1">(c) Microsoft Corporation. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
##-----------------------------------------------------------------------
# Look for a 0.0.0.0 pattern in the build number. 
# If found use it to version the assemblies.
#
# For example, if the 'Build number format' build process parameter 
# $(BuildDefinitionName)_$(Year:yyyy).$(Month).$(DayOfMonth)$(Rev:.r)
# then your build numbers come out like this:
# "Build HelloWorld_2013.07.19.1"
# This script would then apply version 2013.07.19.1 to your assemblies.

# Enable -Verbose option
[CmdletBinding()]
param (

    [Parameter(Mandatory)]
    [ValidateScript({
        If (-not (Test-Path -Path $_)) {
            throw 'Invalid path specified'
        }
        $True
    })]
    [String]$Path,

    [Parameter(Mandatory)]
    [string]$VersionNumber,

    [ValidateNotNullOrEmpty()]
    [string]$VersionRegex,

    $outputversion
)

# Set a flag to force verbose as a default
$VerbosePreference ='Continue' # equiv to -verbose

Write-Verbose "Source Directory: $Path"
Write-Verbose "Version Number/Build Number: $VersionNumber"
Write-Verbose "Version Filter: $VersionRegex"
Write-verbose "Output: Version Number Parameter Name: $outputversion"

# Get and validate the version data
$VersionData = [regex]::matches($VersionNumber,$VersionRegex)
switch($VersionData.Count)
{
   0        
      { 
         Write-Error "Could not find version number data in $VersionNumber."
         exit 1
      }
   1 {}
   default 
      { 
         Write-Warning "Found more than instance of version data in $VersionNumber." 
         Write-Warning "Will assume first instance is version."
      }
}
$NewVersion = $VersionData[0]
Write-Verbose "Version: $NewVersion"

# Apply the version to the assembly property files
$files = Get-ChildItem -Path $Path -Recurse -Include *.nuspec
if($files)
{
    Write-Verbose "Will apply $NewVersion to $($files.count) files."

    foreach ($file in $files) {

        $xml = [xml](get-content -Path $file -Encoding UTF8)
        # we use this format to we ignore any namespace settings at the package level
        $xml.SelectSingleNode("/*[local-name()='package']/metadata/version")
        $xml.package.metadata.version = [string]$NewVersion
        write-verbose -Verbose "Updated the file $file with the version $NewVersion"
        $xml.Save($file)

    }
    Write-Verbose "Set the output variable '$outputversion' with the value $NewVersion"
    Write-Host "##vso[task.setvariable variable=$outputversion;]$NewVersion"
}
else
{
    Write-Warning "Found no files."
}
