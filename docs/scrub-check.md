# 脱敏自检（v6）

分享前逐项查过：

| 项 | 结果 |
| --- | --- |
| 服务器 IP | 无（只有 `127.0.0.1`） |
| 登录密钥 / 凭据 | 无（`accessToken` 一律 `<ACCESS_TOKEN>`） |
| QQ 号 | 无（`<OWNER_QQ>` / `<BOT_QQ>`） |
| API 密钥 | 无（`<API_KEY>`） |
| 声音克隆文件 / 音色 | 无（无音频；`voiceId` 删除，`prefix` 改 `<VOICE_PREFIX>`） |
| 自画像 / 参考图 | 无（包里没有任何图片） |
| 记忆 / 日记 / 聊天 | 无 |
| 盘符写死 | 无（全为 `<DSH_HOME>`、`<WORK_ROOT>`、`<SNOWLUMA_HOME>`、`<DATA_ROOT>`） |
| 人设 / 提示词 | 无（只保留插件能力说明） |

## v6 相对上一版的改动

1. 拆成 **core 最小集** 和 **可选段**，不再一次性全叠上去
2. 去掉三个 `link:` 依赖（别人没源码，装不上）
3. `cordis.patch.yml` 里砍掉了 QQ 语音段，改成独立可选文件
4. 新增 `scripts/check-env.ps1`：装前先验 Node / DSH / 端口
5. 新增 `COMPATIBILITY.md`：每个插件的 Node 与 DSH 版本硬要求
6. README 里写了"上一版为什么用不了"和"报错对照表"
