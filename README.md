# A script to convert NSG data in CSV to ARM templates 
A powershell script to convert CSV file to ARM template for NSG automation. The script itself takes in a CSV file (see example rules.csv for an example) and creates ARM templates as an output.
The solution does not do the actual deployment, but does a test of the deployment. This requires you to be logged in to Azure prior to executing the script. 


## How to use
```
#First login to Azure powershell
Login-AzureRMAccount
#Execute script
convert-csvtoarm.ps1 -filename rules.csv
```
