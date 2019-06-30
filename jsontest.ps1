$version = 1
$baseurl = "https://horizonleeds-api.dev.avamae.co.uk"
$parametersFile = "parameters.json"
$auths = ""

$response = Invoke-RestMethod -Uri ($baseurl + "/v" + $version.ToString() + "/doc.json")

for ($auth in $auths) {

}

$response."paths".PSObject.Properties | ForEach-Object {
    $endpoint = $_.Name
    $_.Value.PSObject.Properties | ForEach-Object {
        $method = $_.Name
        $_.Value.PSObject.Properties | ForEach-Object {
            $
        }
    }
}