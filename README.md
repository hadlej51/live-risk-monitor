# Live Risk Monitor

A real-time PnL and risk monitor for a small paper book of crypto perpetual futures, spot and listed options, built the way a trading firm's risk developer would build it: containers on a Linux box, CI/CD, monitoring, a React dashboard, and an LLM assistant that answers questions by calling the system's own API.

Work in progress. This README becomes the architecture document in the final phase.

## Architecture

```
  exchange websocket (public market data)
            |
            v
  +-------------------+     ticks      +-----------+
  |   feed service    |--------------->| Postgres  |  positions, ticks,
  | parse, reconnect, |                |           |  snapshots, alerts
  | gap detection     |                +-----------+
  +-------------------+                      ^
            | latest prices, pub/sub         |
            v                                |
  +-------------------+   state doc   +-------------------+
  |      Redis        |<------------->|   calc service    |
  +-------------------+               | PnL, VaR, shocks, |
            |                         | options, alerts   |---> Slack/Discord
            v                         +-------------------+
  +-------------------+
  |    API service    |  REST, state websocket, LLM assistant (tool use)
  +-------------------+
            |
            v
  nginx (TLS) ---> React dashboard in the browser

  Prometheus scrapes every service; Grafana shows system health.
  GitHub Actions tests, builds images, and deploys to the box over ssh.
```

## Status

| Phase | What | State |
| --- | --- | --- |
| 0 | Repo and working method | Done |
| 1 | Linux box | In progress |
| 2 | Feed and book | Not started |
| 3 | Risk engine | Not started |
| 3b | Options sleeve | Not started |
| 4 | React dashboard | Not started |
| 5 | Alerts and replay | Not started |
| 6 | CI/CD and observability | Not started |
| 7 | LLM assistant and evals | Not started |
| 8 | Write-up | Not started |

See `docs/00-brief.md` for the full plan.
