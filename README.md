# DeepSeek 智能体示例

> 一套可以照着装、照着改的 **DeepSeek Harness 插件配置样板**。
> 把十几个公开插件拼成一个「有房间、有记忆、会记事、能自己动手」的智能体环境。

版本：**V1**（2026-11-10）
适用：DeepSeek Harness `0.2.2.x`

---

## 这是什么

这不是一套插件，而是**一份配置样板**。

DSH（DeepSeek Harness）本身只是引擎，插件装上去以后长成什么样，全看配置怎么搭。这个仓库把一套实际在用、跑得起来的组合整理成清楚的几层：

- **核心配置**：装完就能跑，界面、桌宠、记忆、文件工具、桌面操作全在里面
- **可选段**：QQ 通道、语音合成、图片生成，按需叠加，不用就完全不装

每一份配置都可以直接复制，里面没有任何人的私密信息。

## 能搭出什么

装上 core 之后，你会得到一个这样的环境：

| 能力 | 来自哪个插件 | 效果 |
| --- | --- | --- |
| 世界线 | `dsh-world` | 一个「家」：固定的房间、每天一篇日记、作息闹钟、会主动开口 |
| 记忆 | `dsh-mnemon` | 跨会话的长记忆，能检索、能引用 |
| 桌面宠物 | `dsh-pet` | 桌面上一只会动的小东西，闲时四处溜达 |
| 桌面操作 | `dsh-computer-use-win` | 截图、点按钮、读窗口树——它真的能替你点鼠标 |
| 运维工具 | `dsh-ops` | 更好用的文件读写、搜索、命令执行 |
| 配置管理 | `dsh-config-manager` | 配置备份、导入、跨机同步 |
| 会话归档 | `@michengai/dsh-archive-manager` | 旧会话收起来不碍事 |
| 插件市场 | `dshmarket` | 在界面里直接找新插件 |

再加上两个可选段，还能多出：

- **QQ 原生通道**：它可以从 QQ 私聊里跟你说话（需要 SnowLuma 做网关）
- **语音与生图**：能说话、能画图（需要 qq-voice-suite 和云端 key）

## 一键部署（懒人版）

不想一条条复制命令的，直接用脚本：

```powershell
# 只想看看它会做什么，不写任何文件
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -DryRun

# 装核心集
powershell -ExecutionPolicy Bypass -File scripts\install.ps1

# 核心集 + QQ 通道（会问你要 QQ 号、令牌、SnowLuma 目录）
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -WithQQ

# 核心集 + 语音生图
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -WithVoice
```

脚本做的事：查 Node 版本 → 找/建 profile 目录 → **备份**原来的 `package.json` 和 `cordis.patch.yml` → 写入核心配置 → 按开关叠加可选段 → `pnpm install`。

- 改写前一定会备份，文件名带时间戳，出问题直接改回来
- 加 `-DryRun` 就只体检不写字
- 装完要**完全退出 DSH 再打开**

## 快速开始

### 第一步：体检

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-env.ps1
```

Node 版本、DSH 装在哪、端口占没占，一条 [X] 就先解决，别急着往下装。

### 第二步：装核心

```powershell
# 把这两个文件放进 profile 目录，一般在这里：
# %USERPROFILE%\.dsh\profiles\desktop\
#   config\core\profile-package.json  -> package.json
#   config\core\cordis.patch.yml      -> cordis.patch.yml

cd "$env:USERPROFILE\.dsh\profiles\desktop"
pnpm install
```

重启 DSH，能开起来就算成了。

### 第三步：按需加可选段

| 想要 | 追加什么 | 前置条件 |
| --- | --- | --- |
| 从 QQ 聊天 | `config/optional/cordis.patch.world-qq.yml` | SnowLuma + 一个小号 |
| 有声音、会画图 | `config/optional/cordis.patch.qqvoice.yml` | qq-voice-suite + 阿里云百炼 key |

把整段贴到 `cordis.patch.yml` 末尾，再把里面的 `<占位符>` 换成自己的值，重启。

## 目录结构

```
config/
  core/                  核心配置：装完就能跑
    profile-package.json   插件清单（bundles + 依赖版本）
    cordis.patch.yml       配置树（各插件的 config 都在这）
  optional/              可选段
    cordis.patch.world-qq.yml    QQ 通道
    cordis.patch.qqvoice.yml     语音 / 生图 MCP
    snowluma-onebot.json         OneBot 网络配置样例
    qqvoice-*.json               语音与生图的参数样例（不含密钥）
    dsh-pet-main-config.jsonc    桌宠样式
    dsh-world-*.json             世界线与主动消息
    worlds-life.json             作息与每日回顾
scripts/
  check-env.ps1          装前体检
  boot-check.ps1         开机自检（参考实现）
  watchdog.ps1           看门狗：谁倒了拉谁（参考实现）
docs/
  compatibility.md       插件引擎要求与报错对照
  scrub-check.md         脱敏自检清单
```

## 版本说明

- **V1**（2026-11-10）首个公开版本。核心集与可选段已拆开，去掉了所有 `link:` 依赖，加了环境体检脚本。

详细变更见 [docs/versions.md](docs/versions.md)。

## 兼容性要点

麻烦的三条，先记住：

1. **Node 必须 `^22.19.0 || >=24.0.0`**。低于这个，`dsh-ops`、`dsh-config-manager` 等五个插件直接装不上。
2. **`dsh-ops` 只吃 DSH `>=0.2.2-rc.1 <0.2.3-0`**。DSH 版本不对就先把它摘掉，其余插件还能用。
3. **peer 警告可以忽略**。那些 `@deepseek-ai/*` 的 peer 由宿主注入，不用单独装。

完整矩阵见 [docs/compatibility.md](docs/compatibility.md)。

## 常见问题

**装完 DSH 打不开 / 某个面板白屏**
先只用 `config/core` 那一份配置树，确认能起来，再一段一段往上贴。

**桌宠不显示**
`dsh-pet` 必须同时出现在 `package.json` 的 `dsh.profile.bundles` 和 `dependencies` 里，少一处就不加载。

**从 QQ 发消息没反应**
两边 `accessToken` 逐字比对；先跑 `curl http://127.0.0.1:3000/get_login_info` 看桥通不通。

**语音发不出去，提示「目标 QQ 号无效：0」**
`<WORK_ROOT>\qq-voice-suite\config.json` 里少了 `{"ownerQQ": 你的号}`。

## 这个仓库里没有什么

只有配置、脚本和文档。**不含**：任何人的图片、音频、日记、记忆、聊天记录、账号、密钥、服务器地址。
凭据一律写成 `<PLACEHOLDER>`，路径一律写成变量。可以放心直接分享。

## 相关仓库

这套配置里用到的三个本地插件，源码也开放了：

| 仓库 | 是什么 |
| --- | --- |
| [qq-mode-console](https://github.com/raging007/qq-mode-console) | DSH 设置页里的 QQ 桥接模式控制台 |
| [qq-agent-presets](https://github.com/raging007/qq-agent-presets) | QQ 桥接用的 agent 预设（qq-chat / qq-chat-v2）+ 工具守卫 |
| [memory-nebula](https://github.com/raging007/memory-nebula) | 跨设备记忆星图（包名 `dsh-memory-nebula`） |

## 版权与致谢

- 配置与脚本部分：MIT
- 插件版权归各自作者所有，本仓库只提供配置示例，不重新分发插件代码
- 部分插件（如 `qq-mode-console`、`qq-agent-presets`、`dsh-memory-nebula`）为本地源码包，需要自备，未包含在本仓库中

## License

[MIT](LICENSE)
