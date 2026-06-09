# Codex DeepSeek for Windows：Windows 小白安装版

这个项目是 **Windows 专用版**，帮你把 DeepSeek V4 接入 Codex。

适用范围：

- Windows 10 / Windows 11
- PowerShell
- Windows 终端里的 `codex` 命令

暂不支持 Mac / Linux。Mac 用户请使用 Mac 版仓库。

## 支持两种用法

| 用法 | 推荐程度 | 适合谁 |
| --- | --- | --- |
| 终端版 `codex -p deepseek` | 推荐 | 日常写代码、改项目 |
| Codex 桌面端 | 可尝试，但要切换配置 | 想在桌面 App 里体验 DeepSeek |

重要提示：桌面端不是在界面里点选 DeepSeek，而是用脚本临时切换配置。

## 你需要准备什么

1. 一台 Windows 电脑。
2. 已安装 Codex，并且终端里能执行 `codex`。
3. 已安装 Node.js LTS，并且终端里能执行 `node`。
4. 一个 DeepSeek API Key。
5. 会打开 PowerShell。

检查命令：

```powershell
codex --version
node --version
```

如果 `codex` 找不到，先安装或修复 Codex CLI。

如果 `node` 找不到，先安装 Node.js LTS：

```text
https://nodejs.org/
```

DeepSeek API Key 格式类似：

```text
<your-deepseek-api-key>
```

不要把真实 API Key 发到 GitHub、论坛、截图或聊天群。

## 第一步：下载项目

打开 PowerShell，复制执行：

```powershell
cd $HOME
git clone https://github.com/zuomian726/codex-deepseek-for-windows.git
cd codex-deepseek-for-windows
```

如果你的 Windows 没有 `git`，可以先安装 Git for Windows：

```text
https://git-scm.com/download/win
```

## 第二步：安装

把 `<your-deepseek-api-key>` 换成你的真实 DeepSeek API Key：

```powershell
powershell -ExecutionPolicy Bypass -File .\deepseek-codex-setup-windows\scripts\install.ps1 -ApiKey "<your-deepseek-api-key>"
```

安装成功后，会看到类似：

```text
Installed DeepSeek Codex profile for Windows.
```

## 第三步：测试

复制执行：

```powershell
codex exec -p deepseek --skip-git-repo-check "只回复 OK"
```

如果看到：

```text
OK
```

说明成功。

## 以后每天怎么用

每次使用前，先启动 DeepSeek 桥接服务：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\start.ps1"
```

进入你的项目目录：

```powershell
cd C:\Code\your-project
```

启动 DeepSeek 版 Codex：

```powershell
codex -p deepseek
```

不用时可以停止桥接服务：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\stop.ps1"
```

## Codex 桌面端使用方法

如果你想让 Codex 桌面端也走 DeepSeek，执行：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\desktop-use-deepseek.ps1"
```

然后必须：

```text
完全退出 Codex 桌面端，再重新打开 Codex 桌面端。
```

如果想恢复默认 OpenAI，执行：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\desktop-use-default.ps1"
```

然后同样完全退出并重新打开 Codex 桌面端。

桌面端注意事项：

- 桌面端切到 DeepSeek 后，每次开机要先执行 `start.ps1`。
- 如果桥接服务没启动，桌面端可能一直连接失败。
- 如果出问题，先执行 `desktop-use-default.ps1` 恢复默认 OpenAI。

## 配置在哪里

一般不用手动改配置。真要改，看这个表：

| 想改什么 | 改哪个文件 |
| --- | --- |
| DeepSeek API Key | `%USERPROFILE%\.codex\.env` |
| 终端版 DeepSeek 模型 | `%USERPROFILE%\.codex\deepseek.config.toml` |
| 桌面端当前模型 | `%USERPROFILE%\.codex\config.toml` |
| 启动桥接 | `%USERPROFILE%\.codex\deepseek-responses-proxy\start.ps1` |
| 停止桥接 | `%USERPROFILE%\.codex\deepseek-responses-proxy\stop.ps1` |
| 桌面端切到 DeepSeek | `%USERPROFILE%\.codex\deepseek-responses-proxy\desktop-use-deepseek.ps1` |
| 桌面端恢复默认 | `%USERPROFILE%\.codex\deepseek-responses-proxy\desktop-use-default.ps1` |

打开配置目录：

```powershell
explorer "$HOME\.codex"
```

## 修改 API Key

重新执行安装脚本即可：

```powershell
powershell -ExecutionPolicy Bypass -File .\deepseek-codex-setup-windows\scripts\install.ps1 -ApiKey "<your-new-deepseek-api-key>"
```

然后重启桥接：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\stop.ps1"
& "$HOME\.codex\deepseek-responses-proxy\start.ps1"
```

## 修改模型

终端版改：

```powershell
notepad "$HOME\.codex\deepseek.config.toml"
```

找到：

```toml
model = "deepseek-v4-pro"
```

可以改成其他 DeepSeek 模型。

如果你用桌面端，改完后要完全退出并重新打开 Codex 桌面端。

## 常见问题

### 1. `codex` 不是内部或外部命令

说明 Codex CLI 没有安装好，或者没有加入 PATH。

先检查：

```powershell
where.exe codex
```

如果找不到，需要先安装或修复 Codex CLI。

### 2. `node` 不是内部或外部命令

说明 Node.js 没有安装好，或者没有加入 PATH。

先检查：

```powershell
node --version
```

如果失败，安装 Node.js LTS：

```text
https://nodejs.org/
```

安装后重新打开 PowerShell。

### 3. PowerShell 不允许执行脚本

使用本项目推荐命令即可绕过当前脚本限制：

```powershell
powershell -ExecutionPolicy Bypass -File .\deepseek-codex-setup-windows\scripts\install.ps1 -ApiKey "<your-deepseek-api-key>"
```

如果是执行已安装的脚本，也可以这样：

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\deepseek-responses-proxy\start.ps1"
```

### 4. `ERROR: Reconnecting... 1/5`

通常是桥接服务没启动。

检查：

```powershell
Invoke-RestMethod http://127.0.0.1:8766/health
```

如果失败，启动桥接：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\start.ps1"
```

然后重新测试：

```powershell
codex exec -p deepseek --skip-git-repo-check "只回复 OK"
```

### 5. DeepSeek `/responses` 404

不要把 Codex 直接指向 DeepSeek 官方地址。

正确配置应该是本地地址：

```toml
base_url = "http://127.0.0.1:8766"
wire_api = "responses"
```

不是：

```toml
base_url = "https://api.deepseek.com"
```

原因是 Codex 会请求 `/responses`，而 DeepSeek 官方接口是 `/chat/completions`。本项目的本地桥接服务就是用来转换这两个接口的。

## 卸载

如果桌面端曾经切到 DeepSeek，先恢复默认：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\desktop-use-default.ps1"
```

停止桥接：

```powershell
& "$HOME\.codex\deepseek-responses-proxy\stop.ps1"
```

删除安装文件：

```powershell
Remove-Item -Recurse -Force "$HOME\.codex\deepseek-responses-proxy"
Remove-Item -Force "$HOME\.codex\deepseek.config.toml"
```

如需删除 API Key：

```powershell
notepad "$HOME\.codex\.env"
```

删除这一行：

```env
DEEPSEEK_API_KEY=<your-deepseek-api-key>
```

## 隐私提醒

不要上传这些内容到 GitHub：

```text
%USERPROFILE%\.codex\.env
真实 API Key
*.log
*.pid
*.sqlite
auth.json
```

这个仓库应该只包含：

```text
README.md
.gitignore
deepseek-codex-setup-windows/
```

## 这个项目做了什么

Codex 当前需要请求：

```text
/responses
```

DeepSeek 当前提供的是：

```text
/chat/completions
```

所以本项目在本机启动一个桥接服务：

```text
Codex -> 本地桥接 -> DeepSeek
```

默认本地地址：

```text
http://127.0.0.1:8766
```

