# 装之前先体检：Node / DSH / pnpm / 端口 / 目录
# 用法：右键用 PowerShell 运行，或者 powershell -ExecutionPolicy Bypass -File check-env.ps1
$ErrorActionPreference = 'Continue'
$ok = @()
$warn = @()
$bad = @()

Write-Output '========== DSH 插件包 · 环境体检 =========='

# 1) Node
$node = (Get-Command node -ErrorAction SilentlyContinue)
if ($node) {
  $v = (& node -v 2>$null).TrimStart('v')
  $major = [int]($v.Split('.')[0]); $minor = [int]($v.Split('.')[1])
  $good = (($major -eq 22) -and ($minor -ge 19)) -or ($major -ge 24)
  if ($good) { $ok += "Node $v（满足 ^22.19 || >=24）" }
  else { $bad += "Node $v（太旧）→ dsh-ops / dsh-config-manager / archive-manager / git-graph / pilot 都会装不上。请装 Node 22.19+ 或 24+" }
} else { $bad += 'Node 没装 → 先装 Node 22.19+ 或 24+' }

# 2) pnpm
$pnpm = (Get-Command pnpm -ErrorAction SilentlyContinue)
if ($pnpm) { $ok += 'pnpm 可用' } else { $warn += 'pnpm 不在 PATH（DSH 桌面版自带一个，也可以在 profile 目录用 corepack）' }

# 3) DSH 本体
$dshExe = 'C:\Users\Administrator\AppData\Local\Programs\DeepSeek Harness\DeepSeek Harness.exe'
$found = Get-ChildItem "$env:LOCALAPPDATA\Programs" -Filter 'DeepSeek Harness.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($found) { $ok += "DSH 在：$($found.FullName)" }
elseif (Test-Path $dshExe) { $ok += "DSH 在：$dshExe" }
else { $warn += '没在默认位置找到 DSH 桌面版，自己确认一下装哪儿了' }

# 4) profile 目录
$profileDir = Join-Path $env:USERPROFILE '.dsh\profiles\desktop'
if (Test-Path $profileDir) { $ok += "已有 profile：$profileDir" }
else { $warn += "还没有 profile 目录（装的时候会建）：$profileDir" }

# 5) 常用端口
foreach ($p in 3000, 3001) {
  $busy = [bool](Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue)
  if ($busy) { $warn += "端口 $p 已被占用（SnowLuma 要用它，先关掉占用的程序）" }
}

# 6) 长路径
if ((Get-Location).Path.Length -gt 120) { $warn += '当前路径很长，Windows 长路径可能让 pnpm 报错，建议换短目录' }

Write-Output ''
Write-Output '--- 通过 ---'
if ($ok.Count) { $ok | ForEach-Object { Write-Output ("  [OK]   " + $_) } } else { Write-Output '  （无）' }
Write-Output '--- 提醒 ---'
if ($warn.Count) { $warn | ForEach-Object { Write-Output ("  [!]    " + $_) } } else { Write-Output '  （无）' }
Write-Output '--- 不通 ---'
if ($bad.Count) { $bad | ForEach-Object { Write-Output ("  [X]    " + $_) } } else { Write-Output '  （无）' }
Write-Output ''
if ($bad.Count -eq 0) { Write-Output '结论：可以往下装。先装 core，跑通再叠加可选段。' }
else { Write-Output '结论：先把 [X] 那几条解决掉，不然 pnpm install 会直接失败。' }
