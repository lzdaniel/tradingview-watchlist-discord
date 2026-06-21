# TradingView Watchlist -> Discord

监控公开 TradingView watchlist：

<https://www.tradingview.com/watchlists/326877343/>

功能：

- 盘中每 15 分钟扫描一次。
- 非盘中每 30 分钟扫描一次。
- watchlist 没变化时不发 Discord。
- 有新增/移除时发送醒目的 Discord 消息。
- 每个交易日开盘和收盘各发送一次完整 watchlist。
- 尽量保留 TradingView 页面里的分类/分组；抓不到分类时归到 `未分类`。

## 安装

```bash
cd /Users/lizhi/Documents/AlgoTrading/tradingview-watchlist-discord
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e .
python -m playwright install chromium
cp .env.example .env
```

编辑 `.env`，至少填入：

```bash
DISCORD_WEBHOOK_URL=<your-discord-webhook-url>
```

## 先测试一次

```bash
source .venv/bin/activate
set -a; source .env; set +a
python -m tv_watchlist_discord.watcher run-once --dry-run
```

第一次运行会建立基线快照，默认不会把全部 symbol 当作新增发送。之后 watchlist 有变化才会发 Discord。

要强制发送完整列表测试：

```bash
python -m tv_watchlist_discord.watcher send-full --label test --dry-run
```

去掉 `--dry-run` 就会真的发送到 Discord。

## 常驻运行

```bash
source .venv/bin/activate
set -a; source .env; set +a
python -m tv_watchlist_discord.watcher daemon
```

调度逻辑：

- 美股正常交易时段，按 `CHECK_INTERVAL_MARKET_SECONDS`，默认 900 秒。
- 其他时间，按 `CHECK_INTERVAL_OFFHOURS_SECONDS`，默认 1800 秒。
- 周一到周五按开盘/收盘发送完整列表；脚本不内置美国节假日表。

## GitHub Actions 部署

这个项目可以放到 GitHub public repo 用 Actions 定时运行。public repo 的标准 GitHub-hosted runner 不消耗个人 private repo 的 2,000 minutes 额度；但仍受 GitHub Actions 的通用限制、排队延迟和 scheduled workflow 规则影响。

需要在 GitHub 仓库里设置 Secret：

```text
DISCORD_WEBHOOK_URL = 你的 Discord webhook
```

workflow 文件：

```text
.github/workflows/tradingview-watchlist.yml
```

运行逻辑：

- `*/15 13-21 * * 1-5` 触发 market 模式；脚本会按 `America/New_York` 判断，只有 09:30-16:00 才真正扫描。
- `7,37 * * * *` 触发 offhours 模式；脚本会在美股正常交易时段跳过，其他时间每 30 分钟扫描。
- `workflow_dispatch` 可以手动运行，支持 `always` / `market` / `offhours`。
- GitHub runner 是一次性的，所以 `state/watchlist_326877343.json` 会提交回 repo，用于下一次比较新增/移除。
- workflow 设置了 `PERSIST_LAST_SEEN=false`，无变化扫描不会仅因为时间戳变化而提交。

注意：如果 repo 是 public，`state/watchlist_326877343.json` 也会公开。这个 watchlist 本身是公开页面，但如果你不想公开快照，就用 private repo 或外部状态存储。

## launchd

`launchd/com.algowatch.tradingview-watchlist-discord.plist.example` 是 macOS launchd 示例。复制到 `~/Library/LaunchAgents/` 前，请先把里面的路径和环境变量确认好。

## 注意

TradingView 没有公开的 watchlist 成员变更订阅 API。这个项目使用 Playwright 读取公开页面并做快照 diff。访问频率已经按你的需求设为较保守的 15/30 分钟；不建议改成高频扫描。
