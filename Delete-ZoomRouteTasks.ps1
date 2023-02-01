#Delete-ZoomRouteTasks
#Script to associate Zoom route scripts with VPN connections & disconnections
#Idea was taken from this script https://xplantefeve.io/posts/SchdTskOnEvent
# Created 1/4/2023
# v1 01-04-2023 - Initial Build 
# V1.1 02-02-2023 Documented code with comments

#Define event IDs we want to bind to
$ConnectedID = 20225
$DisconnectedID = 20226

#Create subscription for binding to events
$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger = $class | New-CimInstance -ClientOnly
$trigger.Enabled = $true
$trigger.Subscription = '<QueryList><Query Id="0" Path="Application"><Select Path="Application"> *[System[Provider[@Name=''RasClient''] and EventID=20226]]</Select></Query></QueryList>'

$ActionParameters = @{
    Execute  = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'
    Argument = '-NoProfile -File C:\temp\Add-ZoomRoutes.ps1'
}

$Action = New-ScheduledTaskAction @ActionParameters
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet

$RegSchTaskParameters = @{
    TaskName    = 'Delete Zoom Routes'
    Description = 'Runs at VPN connection'
    TaskPath    = '\Brightworth\'
    Action      = $Action
    Principal   = $Principal
    Settings    = $Settings
    Trigger     = $Trigger
}

#Create actual task
Register-ScheduledTask @RegSchTaskParameters -Verbose
