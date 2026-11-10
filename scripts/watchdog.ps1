# DSH看门狗：每两分钟看一眼，DSH / SnowLuma / QQ 谁倒了就拉起来
$ErrorActionPreference = 'Continue'
$logDir = '<DATA_ROOT>\health'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'watchdog.log'
function Say($m) {
  $line = ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ' + $m)
  Add-Content -Path $log -Value $line -Encoding UTF8
  # 只留最近 400 行
  $all = Get-Content $log -ErrorAction SilentlyContinue
  if ($all.Count -gt 400) { $all[-400..-1] | Set-Content $log -Encoding UTF8 }
}
function PortUp([int]$p) { return [bool](Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue) }

$fixed = @()

# 1) DSH
if (-not (Get-Process 'DeepSeek Harness' -ErrorAction SilentlyContinue)) {
  Say 'DSH 不在，拉起来'
  Start-Process '<USER_HOME>\AppData\Local\Programs\DeepSeek Harness\DeepSeek Harness.exe'
  $fixed += 'dsh'
}

# 2) SnowLuma
if (-not (PortUp 3000)) {
  Say 'SnowLuma 不在，拉起来'
  Start-Process -FilePath '<SNOWLUMA_HOME>\node.exe' -ArgumentList '<SNOWLUMA_HOME>\index.mjs' -WorkingDirectory '<SNOWLUMA_HOME>' -WindowStyle Hidden
  $fixed += 'snowluma'
}

# 3) QQ 客户端
if (-not (Get-Process QQ -ErrorAction SilentlyContinue)) {
  Say 'QQ 客户端不在，拉起来'
  Start-Process '<QQ_INSTALL_DIR>\QQ.exe' -ArgumentList '/background'
  $fixed += 'qq'
}

if ($fixed.Count -gt 0) { Say ('处理：' + ($fixed -join ',')) }
