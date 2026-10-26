# CLAUDE.md

Live Risk Monitor: a real-time PnL and risk monitor for a small paper book of crypto perpetual, spot and option positions, fed by a public exchange websocket. The full brief is `docs/00-brief.md`. Each phase has its own brief in `docs/NN-phase.md`; read the current one before starting work.

This is a home project. Nothing from a day job: no work data, no work code, no work machine.

## Stack

| Layer | Choice |
| --- | --- |
| Server | Ubuntu 24.04 LTS on a small VPS, administered by hand |
| Feed | One exchange public websocket (Deribit unless the brief says otherwise: perps, spot pairs and options), market data only, no API key |
| Backend | Python 3.12, FastAPI, uvicorn, asyncio, websockets, pydantic |
| Cache, pub/sub | Redis 7 |
| Database | PostgreSQL 16, migrations as plain numbered SQL files in `db/migrations/` |
| Front end | React 18, TypeScript, Vite, one chart library chosen in phase 4 |
| Containers | Docker, one `compose.yaml` for every service |
| CI/CD | GitHub Actions, images in GHCR, deploy over ssh |
| Monitoring | prometheus_client in each service, Prometheus and Grafana containers |
| Reverse proxy | nginx with a Let's Encrypt certificate |
| LLM | Anthropic API with tool use, evals in pytest |
| Tests | pytest, pytest-asyncio, Playwright for front-end smoke tests |
| Lint, types | ruff, mypy (strict on `src/`), tsc |

## Layout

Planned; create directories as the phases need them, not before.

```
services/feed/      exchange websocket client, parser, gap detector
services/calc/      risk engine: PnL, VaR, shocks, greeks, options pricing and smile fit, alerts
services/api/       FastAPI: REST, state websocket, assistant
web/                React dashboard
db/migrations/      numbered SQL files
deploy/             nginx config, systemd unit, deploy script
monitoring/         prometheus.yml, Grafana dashboards
evals/              LLM eval set and harness
docs/               brief, phase briefs, runbook, notes
```

## Where it runs

A personal project with one delivery route: develop on the home machine,
deploy to the VPS. There is no work machine, no work data and no bundle step.
The code still must not assume which of the two it is on: hosts, ports,
credentials and the exchange endpoint live in `.env` and config only.

## Never commit

`.env`, keys, certificates, anything under `data/` or `recordings/`, database
dumps, and the box's IP or username. Set .gitignore before the first commit.

## Entry points

Each service has importable functions that do the work and return a status
the API can surface (feed connected, last tick age, calc latency). The
service's `main` wires them together. No logic in `__main__` blocks.

## Rules

- Every service has tests. A change to a parser, calculation or rule comes with a test that would have caught it breaking.
- No secrets in the repo. Secrets live in `.env` on the box (git-ignored) and in GitHub Actions secrets. `.env.example` lists every variable with a dummy value.
- Logs are structured JSON on stdout, one event per line, with `ts`, `level`, `service` and `event` fields.
- Every container has a health check in `compose.yaml`.
- Paper positions only. No exchange keys with trading permission, no order placement, ever.
- Stay inside the scope guards in `docs/00-brief.md`. If a task seems to need something they rule out, stop and say so instead of building it.
- Stdlib first, but use the stack above rather than hand-rolling an equivalent.
- Measure before optimising. Claims about latency come with the number and how it was measured.
- Small commits with messages that say why. Do not commit generated files, data dumps or `.env`.

## Testing

Tests run against recorded exchange messages and generated data only. No
test opens the live exchange websocket or calls the Anthropic API, except the
eval suite in `evals/`, which runs on its own schedule. Tests that need
Postgres or Redis use the compose services, never the box's.

## Working method

- One brief per phase in `docs/NN-phase.md`, with a done-when test. Build toward that test.
- Two things Clay does by hand: the Linux administration in phase 1 and the first React component in phase 4. For those, explain and review; do not write the commands or code for him to paste.
- Mistakes worth remembering go in `docs/notes.md`: what went wrong, how it was found, what changed. This becomes the phase 8 write-up.

## Commands

`make help` lists them. Targets that need services that don't exist yet will fail until their phase lands.

## Deployment

Filled in during phase 1 (box setup) and phase 6 (pipeline). Until then: nothing deploys automatically.
