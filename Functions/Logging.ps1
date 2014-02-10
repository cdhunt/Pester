function Logging
{
    $writeFlags = @{Host=$false; Verbose=$false; PassThru=$false}
    
    switch ($pester.outputOptions)
    {        
        {![string]::IsNullOrEmpty($_.NUnitXmlFile)} {
            Write-Debug "NUnitXmlFile block"
        }
        {![string]::IsNullOrEmpty($_.NUnitXmlFile)} {
             Write-Debug "LogFile block"
        }
        {$_.WriteHost} {
            Write-Debug "WriteHost block"
            $writeFlags.Host = $true
        }
        {$_.PassThru} {
            Write-Debug "PassThru block"
            $writeFlags.PassThru = $true
        }
        Default {
            Write-Debug "Default block"
            $writeFlags.Verbose = $true
        }
    }

    if ($writeFlags.Host -or $writeFlags.Verbose -or $writeFlags.PassThru) {
        Write-PesterResult @writeFlags
    }
}