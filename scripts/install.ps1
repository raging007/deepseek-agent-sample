<#
  一键部署脚本（DeepSeek 智能体示例 V1）

  用法（最小集，直接装）：
    powershell -ExecutionPolicy Bypass -File scripts\install.ps1

  带 QQ 通道：
    powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -WithQQ -OwnerQQ 你的号 -AccessToken 令牌 -SnowLumaHome "C:\SnowLuma"

  带语音/生图：
    powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -WithVoice -WorkRoot "C:\DeepSeek work"

  说明：脚本只在 profile 目录里写 package.json 和 cordis.patch.yml，改写前会备份成 .bak-时间戳。
#>
param(
  [string]$ProfileName = 'desktop',
  [switch]$WithQQ,
  [switch]$WithVoice,
  [string]$OwnerQQ = '',
  [string]$AccessToken = '',
  [string]$SnowLumaHome = '',
  [string]$WorkRoot = '',
  [switch]$SkipInstall,
  [switch]$DryRun,
  [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Step($m) { Write-Host ''; Write-Host ("== " + $m) -ForegroundColor Cyan }
function Ok($m)   { Write-Host ("   [OK] " + $m) -ForegroundColor Green }
function Warn($m) { Write-Host ("   [!]  " + $m) -ForegroundColor Yellow }
function Die($m)  { Write-Host ("   [X]  " + $m) -ForegroundColor Red; exit 1 }

Step '1/6 环境检查'
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) { Die ' 找不到 node。请先装 Node 22.19+ 或 24+。' }
$v = (& node -v).TrimStart('v')
$parts = $v.Split('.')
$major = [int]$parts[0]; $minor = [int]$parts[1]
if (-not ((($major -eq 22) -and ($minor -ge 19)) -or ($major -ge 24))) {
  Die ("Node {0} 太旧，插件要求 ^22.19 || >=24" -f $v)
}
Ok ("Node " + $v)

$dshHome = Join-Path $env:USERPROFILE '.dsh'
$profileDir = Join-Path $dshHome ('profiles\' + $ProfileName)
Step '2/6 准备 profile 目录'
if (-not (Test-Path $dshHome)) { New-Item -ItemType Directory -Force -Path $dshHome | Out-Null; Ok ("新建 " + $dshHome) }
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null; Ok ("新建 " + $profileDir) }
else { Ok ("已存在 " + $profileDir) }

Step '3/6 备份原配置'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($f in 'package.json','cordis.patch.yml') {
  $p = Join-Path $profileDir $f
  if (Test-Path $p) {
    Copy-Item $p ($p + '.bak-' + $stamp)
    Ok ("备份 " + $f)
  }
}

if ($DryRun) {
  Write-Host ''
  Write-Host '  [DryRun] 到此为止，什么都没写。去掉 -DryRun 才会真的装。' -ForegroundColor Yellow
  Write-Host ('  [DryRun] 目标目录：' + $profileDir)
  exit 0
}

Step '4/6 写入核心配置'
Copy-Item (Join-Path $root 'config\core\profile-package.json') (Join-Path $profileDir 'package.json') -Force
Copy-Item (Join-Path $root 'config\core\cordis.patch.yml') (Join-Path $profileDir 'cordis.patch.yml') -Force
Ok 'package.json / cordis.patch.yml 已写入'

Step '5/6 叠加可选段'
$patch = Join-Path $profileDir 'cordis.patch.yml'
if ($WithQQ) {
  if (-not $OwnerQQ)   { $OwnerQQ = Read-Host ' 你的 QQ 号' }
  if (-not $AccessToken) { $AccessToken = Read-Host ' OneBot accessToken（和 SnowLuma 里一致）' }
  if (-not $SnowLumaHome) { $SnowLumaHome = Read-Host ' SnowLuma 安装目录（默认 C:\SnowLuma）' }
  if (-not $SnowLumaHome) { $SnowLumaHome = 'C:\SnowLuma' }
  $seg = Get-Content (Join-Path $root 'config\optional\cordis.patch.world-qq.yml') -Raw
  $seg = $seg.Replace('<OWNER_QQ>', $OwnerQQ).Replace('<ACCESS_TOKEN>', $AccessToken).Replace('<SNOWLUMA_HOME>', $SnowLumaHome)
  Add-Content -Path $patch -Value ("`n" + $seg) -Encoding UTF8
  Ok '已叠加 QQ 通道配置'
}
if ($WithVoice) {
  if (-not $WorkRoot) { $WorkRoot = Read-Host ' qq-voice-suite 所在根目录（默认 C:\DeepSeek work）' }
  if (-not $WorkRoot) { $WorkRoot = 'C:\DeepSeek work' }
  $seg = Get-Content (Join-Path $root 'config\optional\cordis.patch.qqvoice.yml') -Raw
  $seg = $seg.Replace('<WORK_ROOT>', $WorkRoot).Replace('<DSH_HOME>', $dshHome)
  Add-Content -Path $patch -Value ("`n" + $seg) -Encoding UTF8
  Ok '已叠加语音/生图 MCP 配置'
}
if (-not $WithQQ -and -not $WithVoice) { Ok '只要核心集，跳过可选段' }

Step '6/6 安装依赖'
if ($SkipInstall) { Warn '按参数要求跳过 pnpm install' }
else {
  Push-Location $profileDir
  try {
    $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    if ($pnpm) { & pnpm install }
    else {
      Warn 'pnpm 不在 PATH，尝试用 corepack'
      & corepack pnpm install
    }
    if ($LASTEXITCODE -ne 0) { Warn ("pnpm install 退出码 " + $LASTEXITCODE + '，看上面的报错') }
    else { Ok '依赖装好了' }
  } finally { Pop-Location }
}

Write-Host ''
Write-Host '================ 装完了 ================' -ForegroundColor Green
Write-Host ("profile: " + $profileDir)
Write-Host '下一步：完全退出 DSH 再重新打开（不是最小化）。'
if ($WithQQ) { Write-Host '开完用 QQ 私聊那个小号，看有没有回话。' }
Write-Host '出问题先看 docs\compatibility.md 的报错对照表。'
