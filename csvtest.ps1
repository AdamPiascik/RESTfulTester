 $testcsv = import-csv psycruitclient-api.dev.avamae.co.uk1.csv
  
 foreach($test in $testcsv)
  
   {
  
   $endpoint = $test.("endpoint")
  
   $method = $test.("method")

   $accesstoken = $test.("accesstoken")

   $parameters = $test.("parameters")
   
   $auth_endpoint = "https://psycruitclient-api.dev.avamae.co.uk" + $endpoint
  
    try
    {
        $result = Invoke-WebRequest -Method $method -ContentType 'application/json' -Uri $auth_endpoint -Body $json
        Write-Output($result.StatusCode)
    }
    catch
    {
        Write-Output($_.Exception.Response.StatusCode.value__)
        exit 1
    }
  
   }