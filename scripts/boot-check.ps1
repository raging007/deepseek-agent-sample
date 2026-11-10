# DSH开机自检 v2
# 顺序：拉起 DSH/SnowLuma/QQ → 自己点 QQ 登录 → 查 QQ 桥 → 查插件 → 报平安
$ErrorActionPreference = 'Continue'
$logDir = '<DATA_ROOT>\health'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'latest.log'
$state = Join-Path $logDir 'status.json'
function Say($m) {
  $line = ('[' + (Get-Date -Format 'HH:mm:ss') + '] ' + $m)
  Add-Content -Path $log -Value $line -Encoding UTF8
  Write-Output $line
}
function PortUp([int]$p) { return [bool](Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue) }

Set-Content -Path $log -Value ('=== 开机自检 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ===') -Encoding UTF8
$result = [ordered]@{ at = (Get-Date -Format 's'); snowluma = $false; qqClient = $false; qqLogin = $false; dsh = $false; plugins = @(); notes = @() }
Say '开始'

# ---------- 1) SnowLuma（QQ 桥）----------
if (-not (PortUp 3000)) {
  Say 'SnowLuma 没在听 3000，拉起'
  Start-Process -FilePath '<SNOWLUMA_HOME>\node.exe' -ArgumentList '<SNOWLUMA_HOME>\index.mjs' -WorkingDirectory '<SNOWLUMA_HOME>' -WindowStyle Hidden
  for ($i = 0; $i -lt 30; $i++) { Start-Sleep -Milliseconds 700; if (PortUp 3000) { break } }
}
if (PortUp 3000) { Say 'SnowLuma 在听 3000'; $result.snowluma = $true } else { Say '!! SnowLuma 起不来'; $result.notes += 'snowluma-down' }

# ---------- 2) QQ 客户端 ----------
if (-not (Get-Process QQ -ErrorAction SilentlyContinue)) {
  Say 'QQ 客户端没开，拉起'
  Start-Process '<QQ_INSTALL_DIR>\QQ.exe' -ArgumentList '/background'
  for ($i = 0; $i -lt 20; $i++) { Start-Sleep -Seconds 1; if (Get-Process QQ -ErrorAction SilentlyContinue) { break } }
}
if (Get-Process QQ -ErrorAction SilentlyContinue) { Say 'QQ 客户端在'; $result.qqClient = $true } else { Say '!! QQ 客户端没起来'; $result.notes += 'qq-client-down' }

# ---------- 3) 找 OneBot 配置 ----------
$base = $null; $headers = $null
try {
  $cfg = Get-ChildItem '<SNOWLUMA_HOME>\config\onebot_*.json' -ErrorAction Stop | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  $j = Get-Content $cfg.FullName -Raw | ConvertFrom-Json
  $h = $j.networks.httpServers[0]
  $base = ('http://' + $h.host + ':' + $h.port)
  $headers = @{ Authorization = ('Bearer ' + $h.accessToken) }
  Say ('OneBot 地址 ' + $base)
} catch { Say ('!! 读不到 OneBot 配置：' + $_.Exception.Message); $result.notes += 'onebot-config' }

function GetQqLoginInfo {
  try { return Invoke-RestMethod -Uri ($base + '/get_login_info') -Headers $headers -TimeoutSec 12 } catch { return $null }
}

# ---------- 4) QQ 登录：不通就自己点登录 ----------
$login = $null
if ($base) {
  for ($i = 0; $i -lt 10; $i++) {
    $login = GetQqLoginInfo
    if ($login) { break }
    Start-Sleep -Seconds 2
  }
}
if ($login) {
  Say ('QQ 已登录：' + $login.data.nickname + ' (' + $login.data.user_id + ')')
  $result.qqLogin = $true
} elseif ($base) {
  Say 'QQ 还没登录，试着自己去点登录'
  try {
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    $pids = @((Get-Process QQ -ErrorAction SilentlyContinue).Id)
    $root = [System.Windows.Automation.AutomationElement]::RootElement
    $clicked = $false
    foreach ($qp in $pids) {
      $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $qp)
      $wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $cond)
      foreach ($w in $wins) {
        $bc = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
        $btns = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, $bc)
        foreach ($b in $btns) {
          $n = $b.Current.Name
          if ($n -match '登录|登 录|立即登录|进入|Sign in|Log in') {
            Say ('点按钮：' + $n)
            $p = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
            $p.Invoke()
            $clicked = $true
            break
          }
        }
        if ($clicked) { break }
      }
      if ($clicked) { break }
    }
    if (-not $clicked) { Say '!! 没找到登录按钮（可能免授权自动登，或界面自绘）' }
  } catch { Say ('!! 点登录出错：' + $_.Exception.Message) }
  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 2
    $login = GetQqLoginInfo
    if ($login) { break }
  }
  if ($login) { Say ('QQ 登录成功：' + $login.data.nickname + ' (' + $login.data.user_id + ')'); $result.qqLogin = $true }
  else { Say '!! QQ 仍未登录'; $result.notes += 'qq-not-logged-in' }
}

# ---------- 5) DSH ----------
if (Get-Process 'DeepSeek Harness' -ErrorAction SilentlyContinue) { Say 'DSH 在跑'; $result.dsh = $true }
else { Say '!! DSH 没起'; $result.notes += 'dsh-down' }

# ---------- 6) 插件：profile bundles 是否齐 ----------
$pkg = '<DSH_HOME>\profiles\desktop\package.json'
$mustHave = @('dsh-world','dsh-pet','dsh-mnemon','dsh-memory-nebula','dsh-ops','dsh-computer-use-win')
try {
  $pj = Get-Content $pkg -Raw | ConvertFrom-Json
  $bundles = @($pj.dsh.profile.bundles)
  $missing = @()
  foreach ($m in $mustHave) {
    if ($bundles -notcontains $m) { $missing += $m }
  }
  if ($missing.Count -gt 0) {
    Say ('!! profile bundles 缺：' + ($missing -join ', ') + ' → 补回去')
    $bundles = @($bundles) + $missing
    $pj.dsh.profile.bundles = $bundles
    ($pj | ConvertTo-Json -Depth 12) | Set-Content -Path $pkg -Encoding UTF8
    $result.notes += ('bundles-fixed:' + ($missing -join ','))
    $result.plugins = $missing
  } else { Say '插件 bundles 齐全' }
} catch { Say ('!! 检查插件失败：' + $_.Exception.Message); $result.notes += 'plugin-check-failed' }
foreach ($nm in 'dsh-pet','dsh-world','dsh-mnemon','dsh-memory-nebula') {
  $p = Join-Path '<DSH_HOME>\profiles\desktop\node_modules' $nm
  if (-not (Test-Path $p)) { Say ('!! 插件包不在：' + $nm); $result.notes += ('missing-pkg:' + $nm) }
}

# ---------- 7) 报个平安 ----------
if ($result.qqLogin -and $base) {
  $text = '自检完：桥通了，QQ 登着，DSH 在跑，插件齐。'
  if (-not $result.dsh) { $text = '自检：QQ 通了，但 DSH 没起来。' }
  if (-not $result.snowluma) { $text = '自检：DSH 在，但 QQ 桥没通，我在补。' }
  if ($result.plugins.Count -gt 0) { $text = $text + '（插件补了 ' + ($result.plugins -join '、') + '，重启才生效）' }
  try {
    $body = @{ user_id = <OWNER_QQ>; message = $text } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri ($base + '/send_private_msg') -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 15 | Out-Null
    Say '已报平安'
  } catch { Say ('报平安失败：' + $_.Exception.Message) }
}

($result | ConvertTo-Json -Depth 4) | Set-Content -Path $state -Encoding UTF8
Say '结束'
