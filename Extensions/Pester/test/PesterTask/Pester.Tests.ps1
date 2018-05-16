$taskPath = "$PSScriptRoot\..\..\Task"
$sut = Join-Path -Path $taskPath -ChildPath Pester.ps1 -Resolve

Describe "Testing Pester Task" {

    Context "Testing Task Input" {

        it "ScriptFolder is Mandatory" {
            (Get-Command $sut).Parameters['ScriptFolder'].Attributes.Mandatory | Should -Be $True
        }
        it "Throws Exception when passed an invalid location for ResultsFile" {
            {&$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\RandomFolder } | Should -Throw
        }
        it "Throws Exception when passed an invalid file type for ResultsFile" {
            Mock -CommandName Write-Host -MockWith {}
            {&$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml} | Should -Throw
        }
        it "ResultsFile is Mandatory" {
            (Get-Command $sut).Parameters['ResultsFile'].Attributes.Mandatory | Should -Be $True
        }
        it "Run32Bit is not Mandatory" {
            (Get-Command $sut).Parameters['Run32Bit'].Attributes.Mandatory | Should -Be $False
        }
        it "additionalModulePath is not Mandatory" {
            (Get-Command $sut).Parameters['additionalModulePath'].Attributes.Mandatory | Should -Be $False
        }
        it "CodeCoverageFolder is not Mandatory" {
            (Get-Command $sut).Parameters['CodeCoverageFolder'].Attributes.Mandatory | Should -Be $False
        }
        it "Throws Exception when passed an invalid path for ModuleFolder" {
            {&$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder TestDrive:\RandomFolder} | Should -Throw
        }
        it "Throws Exception when passed a path which doesn't contain Pester for ModuleFolder" {
            {&$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder TestDrive:\} | Should -Throw
        }
        it "ModuleFolder is not Mandatory" {
            (Get-Command $sut).Parameters['ModuleFolder'].Attributes.Mandatory | Should -Be $False
        }
        it "Tag is not Mandatory" {
            (Get-Command $sut).Parameters['Tag'].Attributes.Mandatory | Should -Be $False
        }
        it "additionalModulePath is not Mandatory" {
            (Get-Command $sut).Parameters['additionalModulePath'].Attributes.Mandatory | Should -Be $False
        }
        it "CodeCoverageFolder is not Mandatory" {
            (Get-Command $sut).Parameters['CodeCoverageFolder'].Attributes.Mandatory | Should -Be $False
        }
        it "Calls Invoke-Pester with multiple Tags specified" {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }

            . $Sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -Tag 'Infrastructure,Integration' -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            $Tag.Length | Should Be 2
            Write-Output -NoEnumerate $Tag | Should -BeOfType [System.Array]
            Write-Output -NoEnumerate $Tag | Should -BeOfType [String[]]
        }
        it "ExcludeTag is not Mandatory" {
            (Get-Command $sut).Parameters['ExcludeTag'].Attributes.Mandatory | Should -Be $False
        }
        it "Calls Invoke-Pester with multiple ExcludeTags specified" {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }

            . $Sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ExcludeTag 'Example,Demo' -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            $ExcludeTag.Length | Should be 2
            Write-Output -NoEnumerate $ExcludeTag | Should -BeOfType [System.Array]
            Write-Output -NoEnumerate $ExcludeTag | Should -BeOfType [String[]]
        }

        it "Handles CodeCoverageOutputFile being null from VSTS" {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }

            . $Sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\Output.xml -CodeCoverageOutputFile $null -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Assert-MockCalled Invoke-Pester
        }

        it "Throw an error if CodeCoverageOutputFile is not an xml file" {
            {. $Sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\Output.xml -CodeCoverageOutputFile TestDrive:\codecoverage.csv} | Should Throw
        }
    }

    Context "Testing Task Processing" {
        mock Invoke-Pester { "Tag" } -ParameterFilter {$Tag -and $Tag -eq 'Infrastructure'}
        mock Invoke-Pester { "ExcludeTag" } -ParameterFilter {$ExcludeTag -and $ExcludeTag -eq 'Example'}
        mock Invoke-Pester { "AllTests" }
        mock Import-Module { }
        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Write-Error { }

        it "Calls Invoke-Pester correctly with ScriptFolder and ResultsFile specified" {
            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Assert-MockCalled Invoke-Pester
        }
        it "Calls Invoke-Pester with Tag specified" {
            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -Tag 'Infrastructure' -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Assert-MockCalled Invoke-Pester -ParameterFilter {$Tag -and $Tag -eq 'Infrastructure'}
        }
        it "Calls Invoke-Pester with ExcludeTag specified" {
            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ExcludeTag 'Example' -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Assert-MockCalled Invoke-Pester -ParameterFilter {$ExcludeTag -and $ExcludeTag -eq 'Example'}
        }
        it "Calls Invoke-Pester with the CodeCoverageOutputFile specified" {
            New-Item -Path TestDrive:\ -Name TestFile1.ps1 | Out-Null
            New-Item -Path TestDrive:\ -Name TestFile2.ps1 | Out-Null
            New-Item -Path TestDrive:\ -Name TestFile3.ps1 | Out-Null

            &$Sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\Output.xml -CodeCoverageOutputFile 'TestDrive:\codecoverage.xml' -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Assert-MockCalled Invoke-Pester -ParameterFilter {$CodeCoverageOutputFile -and $CodeCoverageOutputFile -eq 'TestDrive:\codecoverage.xml'}
        }
        it "Should update the `$Env:PSModulePath correctly when additionalModulePath is supplied" {
            &$Sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\Output.xml -additionalModulePath TestDrive:\TestFolder -ForceUseOfPesterInTasks "True"

            $Env:PSModulePath | Should -Match ';{0,1}TestDrive:\\TestFolder;{0,1}'
        }
        it "Should Write-Host the contents of Script parameters as a string version of a hashtable when a hashtable is provided" {
            $Parameters = "@{Path = '$PSScriptRoot\parameters.tests.ps1';Parameters=@{TestValue='SomeValue'}}"
            &$Sut -ScriptFolder $Parameters -ResultsFile TestDrive:\Output.xml -ForceUseOfPesterInTasks 'True'

            Assert-MockCalled -CommandName Write-Host -ParameterFilter {
                $Object -eq "Running Pester from using the script parameter [$Parameters] output sent to [TestDrive:\Output.xml]"
            }
        }
    }

    Context "Testing Task Output" {
        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Import-Module { }
        Mock Write-Error { }
        mock Invoke-Pester {
            param ($OutputFile)
            New-Item -Path $OutputFile -ItemType File
        } -ParameterFilter {$ResultsFile -and $ResultsFile -eq 'TestDrive:\output.xml'}

        mock Invoke-Pester {
            New-Item -Path $CodeCoverageOutputFile -ItemType File
        } -ParameterFilter {$CodeCoverageOutputFile -and $CodeCoverageOutputFile -eq 'TestDrive:\codecoverage.xml'}

        mock Invoke-Pester {}

        it "Creates the output xml file correctly" {
            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Test-Path -Path TestDrive:\Output.xml | Should -Be $True
        }
        it "Throws an error when pester tests fail" {
            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output2.xml -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Assert-MockCalled -CommandName Write-Error
        }

        it "Creates the CodeCoverage output file correctly" {
            New-Item -Path TestDrive:\ -Name TestFile1.ps1 | Out-Null
            New-Item -Path TestDrive:\ -Name TestFile2.ps1 | Out-Null
            New-Item -Path TestDrive:\ -Name TestFile3.ps1 | Out-Null

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -CodeCoverageOutputFile 'TestDrive:\codecoverage.xml' -ForceUseOfPesterInTasks "True" -PesterVersion '4.3.1'
            Test-Path -Path TestDrive:\codecoverage.xml | Should -Be $True
        }

    }

    Context "Testing Pester Module Version Loading" {

        it "Loads Pester version contained in task when ForceUse is set to true " {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }
            Mock Test-Path { return $true } -ParameterFilter { $Path.EndsWith("\4.3.1") }
            Mock Get-ChildItem  { return $true }

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder $null -PesterVersion 4.3.1 -ForceUseOfPesterInTasks "True"

            Assert-MockCalled  Import-Module -ParameterFilter { $Name.EndsWith("\4.3.1\Pester.psd1") }
            Assert-MockCalled Invoke-Pester
        }

        it "Loads Pester version contained in task as Pester not installed on agent and ModuleFolder is Null " {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }
            Mock Test-Path { return $true } -ParameterFilter { $Path.EndsWith("\4.3.1") }
            Mock Get-ChildItem  { return $true }

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder $null -PesterVersion 4.3.1 -ForceUseOfPesterInTasks "False"

            Assert-MockCalled  Import-Module -ParameterFilter { $Name.EndsWith("\4.3.1\Pester.psd1") }
            Assert-MockCalled Invoke-Pester
        }

        it "Loads Pester version contained in task when ForceUse is set to true even when ModuleFolder is set " {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }

            Mock Test-Path { return $true } -ParameterFilter { $Path.EndsWith("$pwd\3.4.3") }
            Mock Get-ChildItem  { return $true }

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder "$pwd\3.4.3" -PesterVersion 4.3.1 -ForceUseOfPesterInTasks "True"

            Assert-MockCalled  Import-Module -ParameterFilter { $Name.EndsWith("\4.3.1\Pester.psd1") }
            Assert-MockCalled Invoke-Pester
        }

        it "Loads Pester version contained in task as Pester not installed on agent and ModuleFolder contains whitespace " {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }
            Mock Test-Path { return $true } -ParameterFilter { $Path.EndsWith("\4.3.1") }
            Mock Get-ChildItem  { return $true }

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder "   " -PesterVersion 4.3.1 -ForceUseOfPesterInTasks "False"

            Assert-MockCalled  Import-Module -ParameterFilter { $Name.EndsWith("\4.3.1\Pester.psd1") }
            Assert-MockCalled Invoke-Pester
        }

        it "Loads Pester version specified by ModuleFolder " {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ModuleFolder "$pwd\3.4.3" -ForceUseOfPesterInTasks "False"
            Assert-MockCalled  Import-Module -ParameterFilter { $Name -eq "$pwd\3.4.3\Pester.psd1" }
            Assert-MockCalled Invoke-Pester
        }

        it "Loads default Pester version if ModuleFolder and Force use of task contained version not set" {
            mock Invoke-Pester { }
            mock Import-Module { }
            Mock Write-Host { }
            Mock Write-Warning { }
            Mock Write-Error { }

            &$sut -ScriptFolder TestDrive:\ -ResultsFile TestDrive:\output.xml -ForceUseOfPesterInTasks "False"
            Assert-MockCalled  Import-Module
            # can't check the previous assert for empty parameters, so check the message
            Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "No Pester module location parameters passed, and not forcing use of Pester in task, so using Powershell default module location" }
            Assert-MockCalled Invoke-Pester
        }

    }

}
