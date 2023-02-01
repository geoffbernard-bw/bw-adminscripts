#Delete-ZoomRoutes
#Script to delete direct routes to Zoom outside of VPN
#It's basically a poor-man's split tunnel
# Created 1/4/2023
# v1 01-04-2023 - Initial Build 
# v1.1 01-10-2023 - Updated method for default route
# v1.2 01-11-2023 - Cleanup

#This script should run during VPN disconnect

# The lines below didn't work when going off and on wifi, wierd multi gateways appeared. See below for another way
#Get default GW
#$MyGW = @((Get-NetRoute "0.0.0.0/0").NextHop)
#$DestinationGW = $MyGW[$MyGW.Count - 1] 

$osrouteresult = route print -4 0.0.0.0
$defgat = $osrouteresult[0..$osrouteresult.count] | ConvertFrom-String | select p3,p4 | where p3 -match '0.0.0.0' | where p4 -notmatch 'On-Link'
$defgat
$DestinationGW = $defgat.P4

Write-host "Default Gateway: $DestinationGW"


# Download text file from Zoom
$ZoomTXTFile = "C:\temp\ZoomPhone.txt"
Invoke-WebRequest -Uri "https://assets.zoom.us/docs/ipranges/ZoomPhone.txt" -OutFile $ZoomTXTFile
[string[]]$ZoomRoutes = Get-Content -Path $ZoomTXTFile


#Add routes into array
#$ZoomRoutes = @("170.14.52.2/32","171.171.171.0/24","1.1.1.1")
write-host "$ZoomRoutes.Count IPs will be added to the route table"


#Foreach to parse Zoom IPs
foreach ($IPBlock in $ZoomRoutes) {
    Write-host "Deleting route to $IPBlock"
    route delete $IPBlock $DestinationGW
    }

#Log event to indicate routes were added

Write-EventLog -EventID 32002 -LogName "Application" -Source "RasClient" -Message "Zoom routes deleted successfully."



