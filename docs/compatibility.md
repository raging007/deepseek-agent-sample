# 兼容矩阵（2026-11-10 实测）

DSH 实测版本：`0.2.2.0`
Node 实测版本：`26.13.0`（但插件要求下限是 22.19，见下）

## 一、插件引擎要求

| 插件 | 版本 | Node 要求 | DSH 要求 | 外部依赖 | 备注 |
| --- | --- | --- | --- | --- | --- |
| `@deepseek-ai/dsh-base` | 内置 | — | — | 无 | DSH 自带 |
| `@deepseek-ai/dsh-web-app` | 内置 | — | — | 无 | DSH 自带 |
| `dshmarket` | 1.73.14 | 无声明 | 无 | 无 | 插件市场 |
| `@michengai/dsh-archive-manager` | 1.2.8 | `^22.19.0 \|\| >=24.0.0` | `>=0.2.0-rc.1 <0.3.0-0` | 无 | 硬要求 Node |
| `@linxin666/dsh-client-ui-git-graph` | 0.4.14 | `^22.19.0 \|\| >=24.0.0` | 无 | 无 | 硬要求 Node |
| `@momasiku/dsh-pilot` | 0.7.2 | `^22.19.0 \|\| >=24.0.0` | 无 | 无 | 硬要求 Node |
| `dsh-world` | 0.7.3 | `>=22.16.0` | `>=0.2.1-rc.2 <0.3.0-0` | 可选 SnowLuma | 世界线、日记、QQ 通道 |
| `dsh-pet` | 0.4.5 | `>=22.12.0` | 无 | 无 | 桌宠；必须同时进 bundles 与 dependencies |
| `dsh-mnemon` | 0.5.42 | `>=20` | `>=0.2.0-rc.2 <0.3.0-0` | 无 | 记忆 |
| `dsh-ops` | 0.5.2 | `^22.19 \|\| >=24` | `>=0.2.2-rc.1 <0.2.3-0` | 无 | **DSH 版本区间最窄** |
| `dsh-computer-use-win` | 0.5.5 | `>=22` | 无 | 无 | Windows 桌面操作 |
| `dsh-config-manager` | 0.6.0 | `^22.19.0 \|\| >=24.0.0` | 无 | 无 | 配置备份/同步 |
| `qq-mode-console` | 0.2.2-r1 | 无声明 | 无 | 无 | **需要源码，link 安装** |
| `qq-agent-presets` | 0.2.2-r1 | 无声明 | 无 | 无 | **需要源码，link 安装** |
| `dsh-memory-nebula` | 0.3.0 | `>=22` | 无 | 无 | **需要源码，link 安装** |

## 二、两个最容易被拒的门槛

1. **Node 版本**：`^22.19.0 || >=24.0.0`。22.12~22.18 一律装不上 `dsh-ops`、`config-manager`、`archive-manager`、`git-graph`、`pilot`。
2. **DSH 版本**：`dsh-ops` 只接受 `>=0.2.2-rc.1 <0.2.3-0`。DSH 是别的版本时，去掉 `dsh-ops` 就能装，但文件/搜索工具会退化回原生工具。

## 三、peerDependencies 说明

多数插件的 peer 由 DSH 宿主提供，不用单独装。`dsh-world` 有 14 个 peer、`dsh-config-manager` 有 18 个，都是 DSH 运行时会注入的模块；如果 `pnpm install` 报一堆 peer 警告，**可以忽略**，只要宿主版本对得上。

## 四、本机实测能跑的组合

```
DSH 0.2.2.0 + Node 26.13.0
bundles: base, web-app, dshmarket, archive-manager, git-graph, dsh-world,
         dsh-pet, dsh-mnemon, dsh-ops, computer-use-win, config-manager, pilot
可选：qq-voice-suite（MCP）+ SnowLuma（OneBot）
```

这三个 link 包在别人机器上要自备源码，所以 `config/core` 里**已经去掉**，需要的人自己再加。
