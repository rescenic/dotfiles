# WSL by default automatically generates hosts according to host, we need to
# add the following entry to /etc/wsl.conf to disable this behavior:
#
# [network]
# generateHosts = false

$WSL_HOST_NAME = "host.wsl";

$FIREWALL_RULE_NAME = "wsl";
$FIREWALL_RULE_DISPLAY_NAME = "WSL";

$HOSTS_FILE_PATH = "$env:SystemRoot\System32\Drivers\etc\hosts";

$HOSTS_FILE_WSL_HOST_PATTERN = "[\d.]+(?=\s+$WSL_HOST_NAME)";

Write-Output "Detecting WSL IP address...";

$hostIP = wsl -- bash -c "tail -1 /etc/resolv.conf | cut -d' ' -f2";
$wslIP = (wsl -- ifconfig eth0 | Select-String -Pattern "inet (\S+)").Matches.Groups[1].Value;

Write-Output "Host IP address: $hostIP";
Write-Output "WSL IP address: $wslIP";

Write-Output "Updating host hosts record $WSL_HOST_NAME ($hostIP)...";

$hostsContent = Get-Content $HOSTS_FILE_PATH;

if ($hostsContent -match $HOSTS_FILE_WSL_HOST_PATTERN) {
  $hostsContent = $hostsContent | ForEach-Object {
    $_ -replace $HOSTS_FILE_WSL_HOST_PATTERN, $hostIP;
  };
} else {
  if ($hostsContent.EndsWith("`r`n")) {
    $hostsContent += "$hostIP`t$WSL_HOST_NAME`r`n";
  } else {
    $hostsContent += "`r`n$hostIP`t$WSL_HOST_NAME";
  }
}

$hostsContent | Out-File $HOSTS_FILE_PATH -Encoding utf8;

Write-Output "Updating firewall rule...";

Remove-NetFireWallRule -Name $FIREWALL_RULE_NAME -ErrorAction Ignore;

New-NetFireWallRule `
  -Name $FIREWALL_RULE_NAME `
  -DisplayName $FIREWALL_RULE_DISPLAY_NAME `
  -Direction Inbound `
  -LocalAddress @($hostIP)`
  -Action Allow;

Write-Output "Done.";