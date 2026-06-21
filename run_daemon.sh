#!/bin/zsh
set -euo pipefail
cd /Users/lizhi/Documents/AlgoTrading/tradingview-watchlist-discord
set -a
source .env
set +a
exec /Users/lizhi/Documents/AlgoTrading/tradingview-watchlist-discord/.venv/bin/python -m tv_watchlist_discord.watcher daemon
