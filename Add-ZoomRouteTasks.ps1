#Add-ZoomRouteTasks
#Script to associate Zoom route scripts with VPN connections & disconnections
#Idea was taken from this script https://xplantefeve.io/posts/SchdTskOnEvent
# Created 1/4/2023
# v1 01-04-2023 - Initial Build 
# V1.1 02-02-2023 Documented code with comments
# v1.2 02-09-2023 - Updated script location from \temp to \scripts

#Define Event IDs we are going to bind to
$ConnectedID = 20225
$DisconnectedID = 20226

#Create task subscription to bind to events
$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger = $class | New-CimInstance -ClientOnly
$trigger.Enabled = $true
$trigger.Subscription = '<QueryList><Query Id="0" Path="Application"><Select Path="Application"> *[System[Provider[@Name=''RasClient''] and EventID=20225]]</Select></Query></QueryList>'

$ActionParameters = @{
    Execute  = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'
    Argument = '-NoProfile -File C:\scripts\Add-ZoomRoutes.ps1'
}

$Action = New-ScheduledTaskAction @ActionParameters
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet

$RegSchTaskParameters = @{
    TaskName    = 'Add Zoom Routes'
    Description = 'Runs at VPN connection'
    TaskPath    = '\Brightworth\'
    Action      = $Action
    Principal   = $Principal
    Settings    = $Settings
    Trigger     = $Trigger
}

#Create actual task
Register-ScheduledTask @RegSchTaskParameters
