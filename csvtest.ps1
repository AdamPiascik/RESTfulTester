$testcsv = import-csv psycruitclient-api.dev.avamae.co.uk1.csv

Out-File -FilePath .\results.txt

$bAllTestPassed = 1

foreach($test in $testcsv){

    $endpoint = $test.("endpoint")  
    $method = $test.("method")
    $accesstoken = $test.("accesstoken")
    $parameters = $test.("parameters")
   
    $auth_endpoint = "https://psycruitclient-api.dev.avamae.co.uk" + $endpoint

    $headers = @{"IsTestData"=1}
    if ($accesstoken) {$headers.Add("Authorization", $accesstoken)}

    try {
        $result = Invoke-WebRequest -Method $method -ContentType 'application/json' -Uri $auth_endpoint -Headers $headers
    }
    catch {
        $bAllTestPassed = 1
        $e = $_.Exception.Response
        Write-Host -NoNewline ("Test of ")
        Write-Host -NoNewline -ForegroundColor Yellow ($endpoint)
        Write-Host(" failed; "`
                    + "here are some (hopefully!) helpful "`
                    + "details:`n")
        Write-Host -NoNewline ("Method: "); Write-Host -ForegroundColor Yellow ($e.Method)
        Write-Host -NoNewline ("Error Code: "); Write-Host -ForegroundColor Yellow ($e.StatusCode.value__.ToString() + " - " + $e.StatusCode)
        Write-Host -NoNewline ("Access token: ")
        if ($accesstoken) { Write-Host ($accesstoken) } else { Write-Host ("None") }
        Write-Host -NoNewline ("Parameters: ")
        if ($parameters) { Write-Host ($parameters)} else { Write-Host ("None") }
        Write-Host $("-" * 40)
    }
}

if ($bAllTestPassed = 1) { exit 0 } else { exit 1 }