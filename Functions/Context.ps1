﻿function Context {
<#
.SYNOPSIS
Provides syntactic sugar for logiclly grouping It blocks within a single Describe block.

.PARAMETER Name
The name of the Context. This is a phrase describing a set of tests within a describe.

.PARAMETER Fixture
Script that is executed. This may include setup specific to the context and one or more It blocks that validate the expected outcomes.

.EXAMPLE
function Add-Numbers($a, $b) {
    return $a + $b
}

Describe "Add-Numbers" {

    Context "when root does not exist" {
         It "..." { ... }
    }

    Context "when root does exist" {
        It "..." { ... }
        It "..." { ... }
        It "..." { ... }
    }
}

.LINK
Describe
It
about_TestDrive

#>
param(
    $name,
    [ScriptBlock] $fixture
)
    $pester.Scope = "Context"
    $TestDriveContent = Get-TestDriveChildItem

    $pester.results = Get-GlobalTestResults
    $pester.margin = " " * $pester.results.TestDepth
    $pester.results.TestDepth += 1
    $pester.results.CurrentContext = $name

    $pester.outputOptions.WriteContextToggle = $true
    # Write-Host -ForegroundColor Magenta $pester.margin $name
    & $fixture
	Clear-TestDrive -Exclude ($TestDriveContent).FullName
   	Clear-Mocks

    $pester.results.TestDepth -= 1
}

