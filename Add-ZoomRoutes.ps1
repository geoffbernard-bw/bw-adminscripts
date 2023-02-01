#Add-ZoomRoutes
#Script to add direct routes to Zoom outside of VPN
#It's basically a poor-man's split tunnel
# Created 1/4/2023
# v1 01-04-2023 - Initial Build
# v1.1 01-09-2023 - Updated method for default route, added logic to kill existing Zoom phone TCP connections
# v1.2 02-01-2023 - Added command to remove route as they are added to prevent double entries

#This script should run during VPN connections
#Get default GW

# The lines below didn't work when going off and on wifi, wierd multi gateways apeared see below for another way
#$MyGW = @((Get-NetRoute "0.0.0.0/0").NextHop)
#$DestinationGW = $MyGW[$MyGW.Count - 1] 


$osrouteresult = route print -4 0.0.0.0
$defgat = $osrouteresult[0..$osrouteresult.count] | ConvertFrom-String | select p3,p4 | where p3 -match '0.0.0.0' | where p4 -notmatch 'On-Link'
$defgat
$DestinationGW = $defgat.P4


Write-host "Default Gateway: $DestinationGW"

# Download text file from Zoom
$ZoomTXTFile = "C:\temp\ZoomPhone.txt"
#
Invoke-WebRequest -Uri "https://assets.zoom.us/docs/ipranges/ZoomPhone.txt" -OutFile $ZoomTXTFile
[string[]]$ZoomRoutes = Get-Content -Path $ZoomTXTFile


#Add routes into array
#$ZoomRoutes = @("170.14.52.2/32","171.171.171.0/24","1.1.1.1")
$ZoomRoutes.Count

#Foreach to parse Zoom IPs
foreach ($IPBlock in $ZoomRoutes) {
    Write-host "Adding route to $IPBlock via $DestinationGW"
	#remove route first, this prevents double entries if moving between networks (wifi to ethernet)
	route delete $IPBlock
    route add $IPBlock $DestinationGW
    }

#reset Zoom Phone process for phone location update
start-sleep -seconds 5
$nsresult = netstat -ano -p tcp
$zoomphoneconndata = $nsresult[3..$nsresult.count] | ConvertFrom-String | select p2,p3,p4,p5,p6 | where p4 -match '5091'
$pidtasktokill = $zoomphoneconndata.P6
if ($pidtasktokill -lt 65535) {
taskkill /f /pid $pidtasktokill
}


#Log event to indicate routes were added
Write-EventLog -EventID 32001 -LogName "Application" -Source "RasClient" -Message "Zoom routes added successfully. DestinationGW = $DestinationGW - Reset PID = $pidtasktokill" 


