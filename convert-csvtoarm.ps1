param(
    [Parameter(Mandatory=$true)]
    [String]$filename
  )

Write-Host $env:BUILD_SOURCESDIRECTORY
$fileindir = "$env:BUILD_SOURCESDIRECTORY\$filename"
$rules = Get-Content $fileindir
$rules =  ConvertFrom-Csv $rules -Delimiter ","
$zones = @()

foreach ($rule in $rules)
{
    if($zones -contains ($rule.'Network rules'))
    {
    }
    else {
        $zones += ($rule.'Network rules')
    }
}
write-host $zones

foreach($zone in $zones){
    $zonerules=@()
    foreach ($rule in $rules){
        if($rule.'Network rules' -eq $zone){
            $rule.source = ($rule.source.Trim().split(";") | ConvertTo-Json)
            $rule.Destination = ($rule.Destination.Trim().split(";") | ConvertTo-Json)
            $rule.port = ($rule.port.Trim().split(";") | ConvertTo-Json)
            $zonerules+=$rule
        }
    }

    $rulesfiles = $zonerules
    $environment = $zone

    $inboundrules = @()
    foreach($rule in $rulesfiles){
        if($rule.direction -eq 'inbound')
        {
            $inboundrules +=$rule
        }
    }

    $outboundrules = @()
    foreach($rule in $rulesfiles){
        if($rule.direction -eq 'outbound')
        {
            $outboundrules +=$rule
        }
    }

    $arm = '{
        "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {  },
        "variables": {  },
        "resources": [ {
        "apiVersion": "2017-06-01",
        "type": "Microsoft.Network/networkSecurityGroups",
        "name": "' + $environment +'-nsg",
        "location": "[resourceGroup().location]",
        "properties": {
        "securityRules": [
            
    '
    foreach($rule in $inboundrules){
        $sourceprefix='""'
        $sourceprefixes='""'
        if($rule.Source.Contains("[")){
            $sourceprefixes=$rule.Source
        }
        else {
            $sourceprefix=$rule.Source
        }
        
        $destinationprefix='""'
        $destinationprefixes='""'
        if($rule.destination.Contains("[")){
            $destinationprefixes=$rule.destination
        }
        else {
            $destinationprefix=$rule.destination
        }


        $jsonrule =  "{
            ""name"": ""IN-$($rule.'Rule_Name')"",
            ""properties"": {
            ""description"": ""$($rule.Description)"",
            ""protocol"": ""$($rule.Protocol)"",
            ""sourcePortRange"": ""*"",
            ""destinationPortRange"": $($rule.port),
            ""sourceAddressPrefixes"": $($sourceprefixes),
            ""destinationAddressPrefixes"": $($destinationprefixes),
            ""sourceAddressPrefix"": $($sourceprefix),
            ""destinationAddressPrefix"": $($destinationprefix),
            ""access"": ""$($rule.Access)"",
            ""priority"": $($rule.'Rule Priority'),
            ""direction"": ""$($rule.Direction)""
            }
        },"
    $arm+=$jsonrule
    }
    foreach($rule in $outboundrules){
        $sourceprefix='""'
        $sourceprefixes='""'
        if($rule.Source.Contains("[")){
            $sourceprefixes=$rule.Source
        }
        else {
            $sourceprefix=$rule.Source
        }
        
        $destinationprefix='""'
        $destinationprefixes='""'
        if($rule.destination.Contains("[")){
            $destinationprefixes=$rule.destination
        }
        else {
            $destinationprefix=$rule.destination
        }

        $jsonrule =  "{
            ""name"": ""OUT-$($rule.'Rule_Name')"",
            ""properties"": {
            ""description"": ""$($rule.'Rule_Name')"",
            ""protocol"": ""$($rule.Protocol)"",
            ""sourcePortRange"": ""*"",
            ""destinationPortRange"": $($rule.port),
            ""sourceAddressPrefixes"": $($sourceprefixes),
            ""destinationAddressPrefixes"": $($destinationprefixes),
            ""sourceAddressPrefix"": $($sourceprefix),
            ""destinationAddressPrefix"": $($destinationprefix),
            ""access"": ""$($rule.Access)"",
            ""priority"": $($rule.'Rule Priority'),
            ""direction"": ""$($rule.Direction)""
            }
        },"
        $arm+=$jsonrule
        }

    $arm = $arm.Substring(0,$arm.Length-1)


    $arm+='      ]
    }   
    }     ],
    "outputs": {  }
    }            '
    $filename = $env:BUILD_SOURCESDIRECTORY+"\"+$environment+'_template.json'
    $arm | out-file $filename
}


foreach($zone in $zones){
    $deploymentname = "nsgdeployment_$zone"
    $filename = "$env:BUILD_SOURCESDIRECTORY\$($zone)_template.json"
    $output = Test-AzureRmResourceGroupDeployment -TemplateFile $filename -ResourceGroupName network-security
    if ($output){
        $o = New-AzureRmResourceGroupDeployment -TemplateFile $filename -ResourceGroupName network-security        -Verbose
        $o
        $o.Details
        throw $0.Details
        
    }
}