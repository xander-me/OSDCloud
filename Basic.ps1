#=======================================================================
#   PreOS: Update-Module
#=======================================================================
Install-Module OSD -Force -SkipPublisherCheck
Import-Module OSD -Force
#=======================================================================
#   OS: Params and Start-OSDCloud
#=======================================================================
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "23H2"
    OSEdition = "Pro"
    OSLanguage = "da-dk"
    OSLicense = "Retail"
    SkipAutopilot = $true
    SkipODT = $true
    ZTI = $true
    Firmware = $false
}
Start-OSDCloud @Params
#=======================================================================
#   PostOS: AutopilotOOBE Configuration
#=======================================================================
$AutopilotOOBEJson = @'
{
    "Assign":  {
                   "IsPresent":  true
               },
    "GroupTag":  "Enterprise",
    "GroupTagOptions":  [
                            "Development",
                            "Enterprise"
                        ],
    "Hidden":  [
                   "AddToGroup",
                   "AssignedComputerName",
                   "AssignedUser"
               ],
    "PostAction":  "Quit",
    "Run":  "PowerShell",
    "Title":  "OSDCloud Autopilot Registration"
}
'@
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force
#=======================================================================
#   PostOS: OOBEDeploy Configuration
#=======================================================================
$OOBEDeployJson = @'
{
    "Autopilot":  {
                      "IsPresent":  true
                  },
    "RemoveAppx":  [
                       "CommunicationsApps",
                       "OfficeHub",
                       "People",
                       "Skype",
                       "Solitaire",
                       "Xbox",
                       "ZuneMusic",
                       "ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

#=======================================================================
#   PostOS: AutopilotOOBE CMD Command Line
#=======================================================================
$AutopilotCmd = @'
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
start PowerShell -NoL -W Mi
start /wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force
start /wait PowerShell -NoL -C Start-AutopilotOOBE -Title 'Autopilot Registration' -GroupTag Enterprise -GroupTagOptions Development,Enterprise -Assign
'@
$AutopilotCmd | Out-File -FilePath "C:\Windows\Autopilot.cmd" -Encoding ascii -Force

#=======================================================================
#   PostOS: Restart-Computer
#=======================================================================
Restart-Computer
