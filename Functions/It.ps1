function It {
<#
.SYNOPSIS
Validates the results of a test inside of a Describe block.

.DESCRIPTION
The It function is intended to be used inside of a Describe 
Block. If you are familiar with the AAA pattern 
(Arrange-Act-Assert), this would be the appropriate location 
for an assert. The convention is to assert a single 
expectation for each It block. The code inside of the It block 
should throw an exception if the expectation of the test is not 
met and thus cause the test to fail. The name of the It block 
should expressively state the expectation of the test.

In addition to using your own logic to test expectations and 
throw exceptions, you may also use Pester's own helper functions 
to assist in evaluating test results using the Should object. 

.PARAMETER Name
An expressive phsae describing the expected test outcome.

.PARAMETER Test
The script block that should throw an exception if the 
expectation of the test is not met.If you are following the 
AAA pattern (Arrange-Act-Assert), this typically holds the 
Assert. 

.EXAMPLE
function Add-Numbers($a, $b) {
    return $a + $b
}

Describe "Add-Numbers" {

    It "adds positive numbers" {
        $sum = Add-Numbers 2 3
        $sum.should.be(5)
    }

    It "adds negative numbers" {
        $sum = Add-Numbers (-2) (-2)
        $sum.should.be((-4))
    }

    It "adds one negative number to positive number" {
        $sum = Add-Numbers (-2) 2
        $sum.should.be(0)
    }

    It "concatenates strings if given strings" {
        $sum = Add-Numbers two three
        $sum.should.be("twothree")
    }

}

.LINK
Describe
Context
about_should
#>
param(
    $name, 
    [ScriptBlock] $test = $(Throw "No test script block is provided. (Have you put the open curly brace on the next line?)")
)
    $pester.results = Get-GlobalTestResults
    $pester.results.TestCount += 1

    Setup-TestFunction
    . $TestDrive\temp.ps1

    $pester.ThisTest=$test
    try{
        [object]$test=(get-variable -name test -scope 1 -errorAction Stop).value
    }
    catch { 
        #throws if there is no parent test var
    }
    $pester.testTime = Measure-Command {
        try{
            temp
        } catch {
            $pester.results.FailedTestsCount += 1
            $PesterException = $_
        }
    }

    $pester.testResult = Get-PesterResult $pester.ThisTest $PesterException
    $pester.results.CurrentDescribe.Tests += $pester.testResult
    $pester.results.TotalTime += $pester.testTime.TotalSeconds
    Logging 
}

function Setup-TestFunction {
@"
function temp {
$test
}
"@ | Microsoft.Powershell.Utility\Out-File $TestDrive\temp.ps1
}


function get-PesterResultObject {
    $pester.humanSeconds = Get-HumanTime $pester.testTime.TotalSeconds
    
    $failureMessage = $pester.testResult.failureMessage
    $stackTrace = $pester.testResult.stackTrace

    [PScustomObject]@{Describes = $pester.testResults.CurrentDescribe.name
                       Context = $pester.testResults.CurrentContext
                       TestDepth = $pester.results.TestDepth
                       Test = $name
                       TestTime = $pester.humanSeconds
                       Success = $pester.testResult.success
    }
}

function write-PesterResult{ 
param([switch]$Host, [switch]$Verbose, [switch]$PassThru)
    
    $testResultObject = get-PesterResultObject
    $pester.margin = " " * $testResultObject.TestDepth
    $pester.error_margin = $pester.margin * 2
    $pester.output = " $($pester.margin)$($testResultObject.Test)"
    $testOutputString = "$($pester.output) $($testResultObject.TestTime)"
    <#
    $pester.margin = " " * $pester.results.TestDepth
    $pester.error_margin = $pester.margin * 2
    $pester.output = " $($pester.margin)$name"
    $pester.humanSeconds = Get-HumanTime $pester.testTime.TotalSeconds
    $output = "$($pester.output) $($pester.humanSeconds)"
    #>

    if ($pester.outputOptions.WriteDescribesToggle)
    {
        $describeOutputString = "$($pester.margin)$($testResultObject.Describes)"
        if ($Host) {
            Write-Host $describeOutputString -ForegroundColor Magenta
        } else {
            Write-Verbose $describeOutputString
        }
        $pester.outputOptions.WriteDescribesToggle = $false
    }

    if ($pester.outputOptions.WriteContextToggle)
    {
        $contextOutputString = "$($pester.margin)$($testResultObject.Context)"
        if ($Host) {
            Write-Host $contextOutputString -ForegroundColor Magenta
        } else {
            Write-Verbose $contextOutputString
        }
        $pester.outputOptions.WriteContextToggle = $false
    }

    if ($testResultObject.Success) {        
        if ($Host) { 
            "[+] $testOutputString" | Write-Host -ForegroundColor DarkGreen
        } elseif ($Verbose) { 
            $testOutputString | Write-Verbose 
        }
    }
    else {
        $failureMessageString = "$($pester.error_margin)$($testResultObject.failureMessage)"
        $stackTraceString = "$($pester.error_margin)$($testResultObject.stackTrace)"

        if ($Host) {
            "[-] $testOutputString" | Write-Host -ForegroundColor red
            Write-Host -ForegroundColor red $failureMessageString
            Write-Host -ForegroundColor red $stackTraceString
        } elseif ($Verbose) {
            $testOutputString | Write-Warning
            $failureMessageString | Write-Warning
            $stackTraceString | Write-Warning
        }
    }

    if ($PassThru)
    {
        Write-Output $testResultObject
    }
    
}

function Get-PesterResult{
    param([ScriptBlock] $test, $exception)
    $testResult = @{
        name = $name
        time = 0
        failureMessage = ""
        stackTrace = ""
        success = $false
    };

    if(!$exception){$testResult.success = $true}
    else {
        $testResult.failureMessage = $Exception.toString() -replace "Exception calling", "Assert failed on"
        if($pester.ShouldExceptionLine) {
            $line=$pester.ShouldExceptionLine
            $pester.ShouldExceptionLine=$null
        }
        else {
            $line=$exception.InvocationInfo.ScriptLineNumber
        }
        $failureLine = $test.StartPosition.StartLine + ($line-2)
        $testResult.stackTrace = "at line: $failureLine in $($test.File)"
    }
    return $testResult
}
