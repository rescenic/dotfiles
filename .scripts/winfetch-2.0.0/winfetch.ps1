#!/usr/bin/env pwsh
#requires -version 5

<#PSScriptInfo
.VERSION 2.0.0
.GUID 1c26142a-da43-4125-9d70-97555cbb1752
.AUTHOR Kied Llaentenn and contributers
.PROJECTURI https://github.com/lptstr/winfetch
.COMPANYNAME
.COPYRIGHT
.TAGS neofetch screenfetch system-info commandline
.LICENSEURI https://github.com/lptstr/winfetch/blob/master/LICENSE
.ICONURI https://lptstr.github.io/lptstr-images/proj/winfetch/logo.png
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS
    Winfetch - Neofetch for Windows in PowerShell 5+
.DESCRIPTION
    Winfetch is a command-line system information utility for Windows written in PowerShell.
.PARAMETER image
    Display a pixelated image instead of the usual logo. Imagemagick required.
.PARAMETER genconf
    Reset your configuration file to the default.
.PARAMETER configpath
    Specify a path to a custom config file.
.PARAMETER noimage
    Do not display any image or logo; display information only.
.PARAMETER switchlogo
    Switch the default Windows logo.
.PARAMETER blink
    Make the logo blink.
.PARAMETER stripansi
    Output without any text effects or colors.
.PARAMETER all
    Display all built-in info segments.
.PARAMETER help
    Display this help message.
.PARAMETER cpustyle
    Specify how to show information level for CPU usage
.PARAMETER memorystyle
    Specify how to show information level for RAM usage
.PARAMETER diskstyle
    Specify how to show information level for disks' usage
.PARAMETER batterystyle
    Specify how to show information level for battery
.PARAMETER showdisks
    Configure which disks are shown, use '-showdisks *' to show all.
.PARAMETER showpkgs
    Configure which package managers are shown, e.g. '-showpkgs scoop,choco'.
.INPUTS
    System.String
.OUTPUTS
    System.String[]
.NOTES
    Run Winfetch without arguments to view core functionality.
#>
[CmdletBinding()]
param(
    [string][alias('i')]$image,
    [switch][alias('g')]$genconf,
    [string][alias('c')]$configpath,
    [switch][alias('n')]$noimage,
    [switch][alias('l')]$switchlogo,
    [switch][alias('b')]$blink,
    [switch][alias('s')]$stripansi,
    [switch][alias('a')]$all,
    [switch][alias('h')]$help,
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$cpustyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$memorystyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$diskstyle = "text",
    [ValidateSet("text", "bar", "textbar", "bartext")][string]$batterystyle = "text",
    [array]$showdisks = @($env:SystemDrive),
    [array]$showpkgs = @("scoop", "choco")
)

$e = [char]0x1B
$ansiRegex = '([\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-ntqry=><~])))'

$is_pscore = $PSVersionTable.PSEdition.ToString() -eq 'Core'

if (-not $configPath) {
    if ($env:WINFETCH_CONFIG_PATH) {
        $configPath = $env:WINFETCH_CONFIG_PATH
    } else {
        $configDir = $env:XDG_CONFIG_HOME, "${env:USERPROFILE}\.config" | Select-Object -First 1
        $configPath = "${configDir}\winfetch\config.ps1"
    }
}

# function to generate percentage bars
function get_percent_bar {
    param ([Parameter(Mandatory)][ValidateRange(0, 100)][int]$percent)

    $x = [char]9632
    $bar = $null

    $bar += "$e[97m[ $e[0m"
    for ($i = 1; $i -le ($barValue = ([math]::round($percent / 10))); $i++) {
        if ($i -le 6) { $bar += "$e[32m$x$e[0m" }
        elseif ($i -le 8) { $bar += "$e[93m$x$e[0m" }
        else { $bar += "$e[91m$x$e[0m" }
    }
    for ($i = 1; $i -le (10 - $barValue); $i++) { $bar += "$e[97m-$e[0m" }
    $bar += "$e[97m ]$e[0m"

    return $bar
}

function get_level_info {
    param (
        [string]$barprefix,
        [string]$style,
        [int]$percentage,
        [string]$text,
        [switch]$altstyle
    )

    switch ($style) {
        'bar' { return "$barprefix$(get_percent_bar $percentage)" }
        'textbar' { return "$text $(get_percent_bar $percentage)" }
        'bartext' { return "$barprefix$(get_percent_bar $percentage) $text" }
        default { if ($altstyle) { return "$percentage% ($text)" } else { return "$text ($percentage%)" }}
    }
}

function truncate_line {
    param (
        [string]$text,
        [int]$maxLength
    )
    $length = ($text -replace $ansiRegex, "").Length
    if ($length -le $maxLength) {
        return $text
    }
    $truncateAmt = $length - $maxLength
    $trucatedOutput = ""
    $parts = $text -split $ansiRegex

    for ($i = $parts.Length - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if (-not $part.StartsWith([char]27) -and $truncateAmt -gt 0) {
            $num = if ($truncateAmt -gt $part.Length) {
                $part.Length
            } else {
                $truncateAmt
            }
            $truncateAmt -= $num
            $part = $part.Substring(0, $part.Length - $num)
        }
        $trucatedOutput = "$part$trucatedOutput"
    }

    return $trucatedOutput
}

# ===== DISPLAY HELP =====
if ($help) {
    if (Get-Command -Name less -ErrorAction Ignore) {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full | less
    } else {
        Get-Help ($MyInvocation.MyCommand.Definition) -Full
    }
    exit 0
}


# ===== VARIABLES =====
$cimSession = New-CimSession
$buildVersion = "$([System.Environment]::OSVersion.Version)"
$legacylogo = $buildVersion -like "6.1*"


# ===== CONFIGURATION =====
$baseConfig = @(
    "title"
    "dashes"
    "os"
    "computer"
    "kernel"
    "motherboard"
    "uptime"
    "resolution"
    "pkgs"
    "pwsh"
    "terminal"
    "theme"
    "cpu"
    "gpu"
    "cpu_usage"
    "memory"
    "disk"
    "battery"
    "locale"
    "local_ip"
    "public_ip"
    "blank"
    "colorbar"
)

$defaultConfig = @'
# ===== WINFETCH CONFIGURATION =====

# $image = "~/winfetch.png"
# $noimage = $true

# Switch the default Windows logo
# $switchlogo = $true

# Make the logo blink
# $blink = $true

# Display all built-in info segments.
# $all = $true

# Add a custom info line
# function info_custom_time {
#     return @{
#         title = "Time"
#         content = (Get-Date)
#     }
# }

# Configure which disks are shown
# $ShowDisks = @("C:", "D:")
# Show all available disks
# $ShowDisks = @("*")

# Configure which package managers are shown
# disabling unused ones will improve speed
# $ShowPkgs = @("scoop", "choco")

# Configure how to show info for levels
# Default is for text only.
# 'bar' is for bar only.
# 'textbar' is for text + bar.
# 'bartext' is for bar + text.
# $cpustyle = 'bar'
# $memorystyle = 'textbar'
# $diskstyle = 'bartext'
# $batterystyle = 'bartext'


# Remove the '#' from any of the lines in
# the following to **enable** their output.

@(
    "title"
    "dashes"
    "os"
    "computer"
    "kernel"
    "motherboard"
    # "custom_time"  # use custom info line
    "uptime"
    "pkgs"
    "pwsh"
    "resolution"
    "terminal"
    # "theme"
    "cpu"
    "gpu"
    # "cpu_usage"  # takes some time
    "memory"
    "disk"
    # "battery"
    # "locale"
    # "local_ip"
    # "public_ip"
    "blank"
    "colorbar"
)

'@

# generate default config
if ($genconf -and (Test-Path $configPath)) {
    $choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
        "overwrite your configuration with the default"
    $choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
        "do nothing and exit"
    $result = $Host.UI.PromptForChoice("Resetting your config to default will overwrite it.",
            "Do you want to continue?", ($choiceYes, $choiceNo), 1)
    if ($result -eq 0) { Remove-Item -Path $configPath } else { exit 1 }
}

if (-not (Test-Path $configPath) -or ((Get-Item -Path $configPath).Length -eq 0)) {
    New-Item -Type File -Path $configPath -Value $defaultConfig -Force | Out-Null
    Write-Host "INFO: saved default config to '$configPath'."
    if ($genconf) { exit 0 }
}

# load config file
$config = . $configPath

if (-not $config -or $all) {
    $config = $baseConfig
}

# prevent config from overriding specified parameters
foreach ($param in $PSBoundParameters.Keys) {
    Set-Variable $param $PSBoundParameters[$param]
}

# convert old config style
if ($config.GetType() -eq [string]) {
    $oldConfig = $config.ToLower()
    $config = $baseConfig | Where-Object { $oldConfig.Contains($PSItem) }
    $config += @("blank", "colorbar")
}

$t = if ($blink) { "5" } else { "1" }
if ($switchlogo) { $legacylogo = -not $legacylogo }

# ===== IMAGE =====
$img = if (-not $noimage) {
    if ($image) {
        if (-not (Get-Command -Name magick -ErrorAction Ignore)) {
            Write-Host 'ERROR: Imagemagick must be installed to print custom images.' -f red
            Write-Host 'hint: if you have Scoop installed, try `scoop install imagemagick`.' -f yellow
            exit 1
        }

        $COLUMNS = 35
        $CURR_ROW = ""
        $CHAR = [Text.Encoding]::UTF8.GetString(@(226, 150, 128)) # 226,150,136
        $upper, $lower = @(), @()

        if ($image -eq 'wallpaper') {
            $image = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
        }
        if (-not (Test-Path -path $image)) {
            Write-Host 'ERROR: Specified image or wallpaper does not exist.' -f red
            exit 1
        }
        $pixels = @((magick convert -thumbnail "${COLUMNS}x" $image txt:-).Split("`n"))
        foreach ($pixel in $pixels) {
            # ignore comments in output
            if ($pixel.StartsWith("#")) { continue }

            $col, $row = [regex]::Match($pixel, "(\d+),(\d+):").Groups[1, 2].Value
            $r, $g, $b = [regex]::Match($pixel, "\((\d+).*?,(\d+).*?,(\d+).*?,(\d+).*?\)").Groups[1, 2, 3].Value

            if (($row % 2) -eq 0) {
                $upper += "${r};${g};${b}"
            } else {
                $lower += "${r};${g};${b}"
            }

            if (($row % 2) -eq 1 -and $col -eq ($COLUMNS - 1)) {
                $i = 0
                while ($i -lt $COLUMNS) {
                    $CURR_ROW += "${e}[38;2;$($upper[$i]);48;2;$($lower[$i])m${CHAR}"
                    $i++
                }
                "${CURR_ROW}${e}[0m"

                $CURR_ROW = ""
                $upper = @()
                $lower = @()
            }
        }
    } elseif ($legacylogo) {
        @(
            "${e}[${t};31m        ,.=:!!t3Z3z.,               "
            "${e}[${t};31m       :tt:::tt333EE3               "
            "${e}[${t};31m       Et:::ztt33EEE  ${e}[32m@Ee.,      ..,"
            "${e}[${t};31m      ;tt:::tt333EE7 ${e}[32m;EEEEEEttttt33#"
            "${e}[${t};31m     :Et:::zt333EEQ. ${e}[32mSEEEEEttttt33QL"
            "${e}[${t};31m     it::::tt333EEF ${e}[32m@EEEEEEttttt33F "
            "${e}[${t};31m    ;3=*^``````'*4EEV ${e}[32m:EEEEEEttttt33@. "
            "${e}[${t};34m    ,.=::::it=., ${e}[31m`` ${e}[32m@EEEEEEtttz33QF  "
            "${e}[${t};34m   ;::::::::zt33)   ${e}[32m'4EEEtttji3P*   "
            "${e}[${t};34m  :t::::::::tt33 ${e}[33m:Z3z..  ${e}[32m```` ${e}[33m,..g.   "
            "${e}[${t};34m  i::::::::zt33F ${e}[33mAEEEtttt::::ztF    "
            "${e}[${t};34m ;:::::::::t33V ${e}[33m;EEEttttt::::t3     "
            "${e}[${t};34m E::::::::zt33L ${e}[33m@EEEtttt::::z3F     "
            "${e}[${t};34m{3=*^``````'*4E3) ${e}[33m;EEEtttt:::::tZ``     "
            "${e}[${t};34m            `` ${e}[33m:EEEEtttt::::z7       "
            "${e}[${t};33m                'VEzjt:;;z>*``       "
        )
    } else {
        @(
            "${e}[${t};34m                    ....,,:;+ccllll"
            "${e}[${t};34m      ...,,+:;  cllllllllllllllllll"
            "${e}[${t};34m,cclllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34m                                   "
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34mllllllllllllll  lllllllllllllllllll"
            "${e}[${t};34m``'ccllllllllll  lllllllllllllllllll"
            "${e}[${t};34m      ``' \\*::  :ccllllllllllllllll"
            "${e}[${t};34m                       ````````''*::cll"
            "${e}[${t};34m                                 ````"
        )
    }
}


# ===== BLANK =====
function info_blank {
    return @{}
}


# ===== COLORBAR =====
function info_colorbar {
    return @(
        @{
            title   = ""
            content = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}{0}[0m') -f $e, '   '
        },
        @{
            title   = ""
            content = ('{0}[0;100m{1}{0}[0;101m{1}{0}[0;102m{1}{0}[0;103m{1}{0}[0;104m{1}{0}[0;105m{1}{0}[0;106m{1}{0}[0;107m{1}{0}[0m') -f $e, '   '
        }
    )
}


# ===== OS =====
function info_os {
    return @{
        title   = "OS"
        content = if ($IsWindows -or $PSVersionTable.PSVersion.Major -eq 5) {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption,OSArchitecture -CimSession $cimSession
            "$($os.Caption.TrimStart('Microsoft ')) [$($os.OSArchitecture)]"
        } else {
            ($PSVersionTable.OS).TrimStart('Microsoft ')
        }
    }
}


# ===== MOTHERBOARD =====
function info_motherboard {
    $motherboard = Get-CimInstance Win32_BaseBoard -CimSession $cimSession -Property Manufacturer,Product
    return @{
        title = "Motherboard"
        content = "{0} {1}" -f $motherboard.Manufacturer, $motherboard.Product
    }
}


# ===== TITLE =====
function info_title {
    return @{
        title   = ""
        content = "${e}[1;34m{0}${e}[0m@${e}[1;34m{1}${e}[0m" -f [System.Environment]::UserName,$env:COMPUTERNAME
    }
}


# ===== DASHES =====
function info_dashes {
    $length = [System.Environment]::UserName.Length + $env:COMPUTERNAME.Length + 1
    return @{
        title   = ""
        content = "-" * $length
    }
}


# ===== COMPUTER =====
function info_computer {
    $compsys = Get-CimInstance -ClassName Win32_ComputerSystem -Property Manufacturer,Model -CimSession $cimSession
    return @{
        title   = "Host"
        content = '{0} {1}' -f $compsys.Manufacturer, $compsys.Model
    }
}


# ===== KERNEL =====
function info_kernel {
    return @{
        title   = "Kernel"
        content = $buildVersion
    }
}


# ===== UPTIME =====
function info_uptime {
    @{
        title   = "Uptime"
        content = $(switch ((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem -Property LastBootUpTime -CimSession $cimSession).LastBootUpTime) {
            ({ $PSItem.Days -eq 1 }) { '1 day' }
            ({ $PSItem.Days -gt 1 }) { "$($PSItem.Days) days" }
            ({ $PSItem.Hours -eq 1 }) { '1 hour' }
            ({ $PSItem.Hours -gt 1 }) { "$($PSItem.Hours) hours" }
            ({ $PSItem.Minutes -eq 1 }) { '1 minute' }
            ({ $PSItem.Minutes -gt 1 }) { "$($PSItem.Minutes) minutes" }
        }) -join ' '
    }
}


# ===== RESOLUTION =====
function info_resolution {
    Add-Type -AssemblyName System.Windows.Forms
    $displays = foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        "$($monitor.Bounds.Size.Width)x$($monitor.Bounds.Size.Height)"
    }

    return @{
        title   = "Resolution"
        content = $displays -join ', '
    }
}


# ===== TERMINAL =====
# this section works by getting the parent processes of the current powershell instance.
function info_terminal {
    if (-not $is_pscore) {
        $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $PID" -Property ParentProcessId -CimSession $cimSession).ParentProcessId
        for () {
            if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
                $parent = Get-Process -Id (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($parent.ID)" -Property ParentProcessId -CimSession $cimSession).ParentProcessId
                continue
            }
            break
        }
    } else {
        $parent = (Get-Process -Id $PID).Parent
        for () {
            if ($parent.ProcessName -in 'powershell', 'pwsh', 'winpty-agent', 'cmd', 'zsh', 'bash') {
                $parent = (Get-Process -Id $parent.ID).Parent
                continue
            }
            break
        }
    }
    try {
        $terminal = switch ($parent.ProcessName) {
            { $PSItem -in 'explorer', 'conhost' } { 'Windows Console' }
            'Console' { 'Console2/Z' }
            'ConEmuC64' { 'ConEmu' }
            'WindowsTerminal' { 'Windows Terminal' }
            'FluentTerminal.SystemTray' { 'Fluent Terminal' }
            'Code' { 'Visual Studio Code' }
            default { $PSItem }
        }
    } catch {
        $terminal = $parent.ProcessName
    }

    return @{
        title   = "Terminal"
        content = $terminal
    }
}


# ===== THEME =====
function info_theme {
    $themeinfo = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name SystemUsesLightTheme, AppsUseLightTheme
    $systheme = if ($themeinfo.SystemUsesLightTheme) { "Light" } else { "Dark" }
    $apptheme = if ($themeinfo.AppsUseLightTheme) { "Light" } else { "Dark" }
    return @{
        title = "Theme"
        content = "System - $systheme, Apps - $apptheme"
    }
}


# ===== CPU/GPU =====
function info_cpu {
    return @{
        title   = "CPU"
        content = (Get-CimInstance -ClassName Win32_Processor -Property Name -CimSession $cimSession).Name
    }
}

function info_gpu {
    return @{
        title   = "GPU"
        content = (Get-CimInstance -ClassName Win32_VideoController -Property Name -CimSession $cimSession).Name
    }
}


# ===== CPU USAGE =====
function info_cpu_usage {
    $loadpercent = (Get-CimInstance -ClassName Win32_Processor -Property LoadPercentage -CimSession $cimSession).LoadPercentage
    $proccount = (Get-Process).Count
    return @{
        title   = "CPU Usage"
        content = get_level_info "" $cpustyle $loadpercent "$proccount processes" -altstyle
    }
}


# ===== MEMORY =====
function info_memory {
    $m = Get-CimInstance -ClassName Win32_OperatingSystem -Property TotalVisibleMemorySize,FreePhysicalMemory -CimSession $cimSession
    $total = $m.TotalVisibleMemorySize / 1mb
    $used = ($m.TotalVisibleMemorySize - $m.FreePhysicalMemory) / 1mb
    $usage = [math]::floor(($used / $total * 100))
    return @{
        title   = "Memory"
        content = get_level_info "   " $memorystyle $usage "$($used.ToString("#.##")) GiB / $($total.ToString("#.##")) GiB"
    }
}


# ===== DISK USAGE =====
function info_disk {
    [System.Collections.ArrayList]$lines = @()

    function to_units($value) {
        if ($value -gt 1tb) {
            return "$([math]::round($value / 1tb, 1)) TiB"
        } else {
            return "$([math]::floor($value / 1gb)) GiB"
        }
    }

    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Property Size,FreeSpace -CimSession $cimSession

    foreach ($diskInfo in $disks) {
        foreach ($diskLetter in $showDisks) {
            if ($diskInfo.DeviceID -eq $diskLetter -or $diskLetter -eq "*") {
                $total = $diskInfo.Size
                $used = $total - $diskInfo.FreeSpace
                $usage = [math]::floor(($used / $total * 100))
                [void]$lines.Add(@{
                    title   = "Disk ($($diskInfo.DeviceID))"
                    content = get_level_info "" $diskstyle $usage "$(to_units $used) / $(to_units $total)"
                })
                break
            }
        }
    }

    return $lines
}


# ===== POWERSHELL VERSION =====
function info_pwsh {
    return @{
        title   = "Shell"
        content = "PowerShell v$($PSVersionTable.PSVersion)"
    }
}


# ===== PACKAGES =====
function info_pkgs {
    $pkgs = @()

    if ("choco" -in $ShowPkgs -and (Get-Command -Name choco -ErrorAction Ignore)) {
        $chocopkg = (& clist -l)[-1].Split(' ')[0] - 1

        if ($chocopkg) {
            $pkgs += "$chocopkg (choco)"
        }
    }

    if ("scoop" -in $ShowPkgs) {
        if (Test-Path "~/scoop/apps") {
            $scoopdir = "~/scoop/apps"
        } elseif (Get-Command -Name scoop -ErrorAction Ignore) {
            $scoop = & scoop which scoop
            $scoopdir = (Resolve-Path "$(Split-Path -Path $scoop)\..\..\..").Path
        }

        if ($scoopdir) {
            $scooppkg = (Get-ChildItem -Path $scoopdir -Directory).Count - 1
        }

        if ($scooppkg) {
            $pkgs += "$scooppkg (scoop)"
        }
    }

    if (-not $pkgs) {
        $pkgs = "(none)"
    }

    return @{
        title   = "Packages"
        content = $pkgs -join ', '
    }
}


# ===== BATTERY =====
function info_battery {
    $battery = Get-CimInstance Win32_Battery -CimSession $cimSession -Property BatteryStatus,EstimatedChargeRemaining,EstimatedRunTime,TimeToFullCharge

    if (-not $battery) {
        return @{
            title = "Battery"
            content = "(none)"
        }
    }

    $power = Get-CimInstance BatteryStatus -Namespace root\wmi -CimSession $cimSession -Property Charging,PowerOnline

    $status = if ($power.Charging) {
        "Charging"
    } elseif ($power.PowerOnline) {
        "Plugged in"
    } else {
        "Discharging"
    }

    $timeRemaining = if ($power.Charging) {
        $battery.TimeToFullCharge
    } else {
        $battery.EstimatedRunTime
    }

    # don't show time remaining if windows hasn't properly reported it yet
    $timeFormatted = if ($timeRemaining -and $timeRemaining -lt 71582788) {
        $hours = [math]::floor($timeRemaining / 60)
        $minutes = $timeRemaining % 60
        ", ${hours}h ${minutes}m"
    }

    return @{
        title = "Battery"
        content = get_level_info "  " $batterystyle $battery.EstimatedChargeRemaining "$status$timeFormatted" -altstyle
    }
}


# ===== LOCALE =====
function info_locale {
    # `Get-WinUserLanguageList` has a regression bug on PowerShell v7.1+
    # https://github.com/PowerShell/PowerShellModuleCoverage/issues/18
    # Fallback to `Get-WinSystemLocale` (which might be slightly inaccurate) for such cases
    return @{
        title = "Locale"
        content = if ($PSVersionTable.PSVersion -like "7.1.*") {
            "$((Get-WinHomeLocation).HomeLocation) - $((Get-WinSystemLocale).DisplayName)"
        } else {
            "$((Get-WinHomeLocation).HomeLocation) - $((Get-WinUserLanguageList)[0].LocalizedName)"
        }
    }
}


# ===== IP =====
function info_local_ip {
    $indexDefault = Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object -Property RouteMetric | Select-Object -First 1 | Select-Object -ExpandProperty ifIndex
    $local_ip = Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $indexDefault | Select-Object -ExpandProperty IPAddress
    return @{
        title = "Local IP"
        content = $local_ip
    }
}

function info_public_ip {
    try {
        $public_ip = (Resolve-DnsName -Name myip.opendns.com -Server resolver1.opendns.com).IPAddress
    } catch {}

    if (-not $public_ip) {
        $public_ip = Invoke-RestMethod -Uri https://ifconfig.me/ip
    }

    return @{
        title = "Public IP"
        content = $public_ip
    }
}


if (-not $stripansi) {
    # unhide the cursor after a terminating error
    trap { "$e[?25h"; break }

    # reset terminal sequences and display a newline
    Write-Output "$e[0m$e[?25l"
} else {
    Write-Output ""
}

# write logo
if (-not $stripansi) {
    foreach ($line in $img) {
        Write-Output " $line"
    }
}

$writtenLines = 0
$freeSpace = $Host.UI.RawUI.WindowSize.Width - 1

# move cursor to top of image and to column 40
if ($img -and -not $stripansi) {
    $freeSpace -= 1 + 35 + 3
    Write-Output "$e[$($img.Length + 1)A"
}


# write info
foreach ($item in $config) {
    if (Test-Path Function:"info_$item") {
        $info = & "info_$item"
    } else {
        $info = @{ title = "$e[31mfunction 'info_$item' not found" }
    }

    if (-not $info) {
        continue
    }

    if ($info -isnot [array]) {
        $info = @($info)
    }

    foreach ($line in $info) {
        $output = "$e[1;34m$($line["title"])$e[0m"

        if ($line["title"] -and $line["content"]) {
            $output += ": "
        }

        $output += "$($line["content"])"

        if ($img) {
            if (-not $stripansi) {
                # move cursor to column 40
                $output = "$e[40G$output"
            } else {
                # write image progressively
                $imgline = ("$($img[$writtenLines])"  -replace $ansiRegex, "").PadRight(35)
                $output = " $imgline   $output"
            }
        }

        $writtenLines++

        if ($stripansi) {
            $output = $output -replace $ansiRegex, ""
            if ($output.Length -gt $freeSpace) {
                $output = $output.Substring(0, $output.Length - ($output.Length - $freeSpace))
            }
        } else {
            $output = truncate_line $output $freeSpace
        }

        Write-Output $output
    }
}

if ($stripansi) {
    # write out remaining image lines
    for ($i = $writtenLines; $i -lt $img.Length; $i++) {
        $imgline = ("$($img[$i])"  -replace $ansiRegex, "").PadRight(35)
        Write-Output " $imgline"
    }
}

# move cursor back to the bottom and print 2 newlines
if (-not $stripansi) {
    $diff = $img.Length - $writtenLines
    if ($img -and $diff -gt 0) {
        Write-Output "$e[${diff}B"
    } else {
        Write-Output ""
    }
    Write-Output "$e[?25h"
} else {
    Write-Output "`n"
}

#  ___ ___  ___
# | __/ _ \| __|
# | _| (_) | _|
# |___\___/|_|
#
