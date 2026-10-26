# Live Risk Monitor: skills project

Oct 24, 2026 · @Clay Hadley

## Goal

Build and run a small real-time risk monitor the way a trading firm's risk developer would, so that every line in the DV Trading posting has a working example behind it, along with the quant lines of a Group One Trading options market-making posting (options pricing, vol surfaces, risk measures, microstructure, evaluating model behaviour). The system is deliberately modest. The point is the engineering around it: containers, a Linux box you administer, CI, monitoring, a React front end, a live data feed, and an LLM feature with tool calling and an eval set.

The product at the end: a public GitHub repo with a README that walks through the architecture, a running instance on a Linux server you control, and a short write-up of what broke and what you did about it. Fourteen to eighteen weeks at five to eight hours a week.

This is a home project. Nothing from Aegon, no work data, no work machine.

## Skills map

Each gap from the posting and the phase that covers it. Strengths you already have are listed so the project does not spend time on them.

| Posting line | Where you stand | Covered in |
| --- | --- | --- |
| 4+ years as a full-stack developer | Gap on paper. Cannot be fixed, only offset by a real shipped system | Whole project, the README is the evidence |
| Python for backend logic and model integration | Strong | Phase 2 |
| Docker, CI/CD pipelines | Jenkins only, no containers | Phases 1 and 6 |
| Linux administration | Gap | Phase 1, and every phase after runs on that box |
| Monitoring and logging, Prometheus and Grafana | Gap | Phase 6 |
| Kubernetes, Terraform, Ansible (plus) | Gap, leave out | Not covered, see scope guards |
| AI coding assistants, agentic workflows | Strong | Working method, same as the peers build |
| LLM API integration, prompt design, tool calling, evaluation | Partial. Tool calling and evals are the thin spots | Phase 7 |
| React, Angular or Vue | Gap | Phase 4 |
| SQL, PostgreSQL, Redis | SQL strong, Postgres and Redis new | Phases 2 and 3 |
| Data structures, APIs, real-time processing | Batch only so far | Phases 2 and 3 |
| Real-time data visualization | Gap | Phase 4 |
| Quant models, working with quants | Strong | Phase 5, and it is what makes the project credible |
| Stakeholders | Strong | Not covered |
| Options pricing models, implied volatility surfaces (Group One) | Gap in code, known as a user | Phase 3b |
| Evaluating model or strategy behaviour (Group One) | Partial | Phase 3 VaR backtest, phase 3b IV residuals against the exchange |
| Market microstructure (Group One) | Gap | Phase 3, spread, microprice and trade-flow imbalance |
| C#, C++ (Group One) | Gap, leave out | Not covered. The posting values engineering ability over a language |

## The system

A live PnL and risk monitor for a small book of crypto perpetual futures, spot and listed options positions, fed by one free public exchange websocket (Deribit, which carries perps, spot pairs and options on the same connection). Crypto is the data source because it is the only free, 24/7, real-time feed with real volatility. The positions are paper, defined in a config file, no money involved.

What it does, in data order:

1. Subscribes to trade and book-top streams for a handful of instruments (BTC, ETH and a few others) on one exchange, plus option tickers for one underlying, with reconnect and gap detection.
2. Maintains a position book: paper positions with entry prices, loaded from Postgres, editable from the front end.
3. Computes on every tick: mark-to-market PnL per position and total, intraday high and low water marks, realised volatility over rolling windows, and a parametric and historical VaR refreshed every minute.
4. Computes risk slides: PnL under a grid of price shocks per instrument (and price by vol for options), delta and gamma for the perpetuals, and full greeks plus vega by expiry for the options sleeve, priced off a fitted volatility smile.
5. Publishes the current state to Redis and pushes it over a websocket to the browser.
6. Serves a React dashboard: live PnL tiles, a position table, a price and PnL chart, the VaR line, the slide grid, and an alerts panel.
7. Raises alerts on rules (PnL below a floor, VaR above a limit, feed stale for more than N seconds) and delivers them to the dashboard and to a Slack or Discord webhook.
8. Persists ticks and one-minute snapshots to Postgres so the dashboard can replay a day.
9. Exposes an LLM assistant that answers questions like "why is PnL down since 09:30" by calling the system's own API as tools, with an eval set that scores its answers against known states.
10. Runs in Docker on a Linux server you administer, deployed by a GitHub Actions pipeline, with Prometheus metrics and a Grafana dashboard for the system itself (tick rate, latency, feed gaps, error counts).

Steps 1 to 5 are the backend, 6 the front end, 7 and 8 operations, 9 the LLM feature, 10 the DevOps layer. The phases below build them in roughly that order, with the Linux box first because everything else lands on it.

## Stack

Every choice matches the posting or the most common answer in that kind of shop. Where two options are equally common, the simpler one.

| Component | Choice | Why |
| --- | --- | --- |
| Server | Ubuntu 24.04 LTS on a small VPS (Hetzner or DigitalOcean, about $6 a month) | A box you ssh into and administer. WSL2 at home is fine for development but does not count as Linux administration |
| Feed | Deribit public websocket (JSON-RPC) | Free, no key needed for public channels, 24/7, and the one free venue with perps and listed options on the same connection |
| Backend | Python 3.12, FastAPI, uvicorn, asyncio, websockets | Python is required. FastAPI is the standard answer for a Python service with websockets |
| Cache and pub/sub | Redis | Named in the posting. Holds latest state and fans ticks out to the web layer |
| Database | PostgreSQL 16 | Named in the posting. Positions, ticks, snapshots, alerts, eval results |
| Front end | React 18 with TypeScript, Vite, a charting library (Recharts or lightweight-charts) | React is the most common of the three named. TypeScript because every React shop uses it |
| Containers | Docker, Docker Compose | One compose file runs feed, api, redis, postgres, prometheus, grafana |
| CI/CD | GitHub Actions | Named in the posting. pytest, lint, type check, build images, deploy over ssh |
| Monitoring | Prometheus client in the backend, Prometheus and Grafana containers, alertmanager optional | Named in the posting |
| Reverse proxy | nginx or Caddy with TLS | Standard on a Linux box exposing a web app |
| LLM | Anthropic API with tool use, a small eval harness in pytest | Named in the posting. Claude tool calling against your own API |
| Tests | pytest, pytest-asyncio, Playwright for one or two front-end smoke tests | Tested code is in the responsibilities |

Keep the Python side stdlib-first the way you do at work, but do not avoid the libraries above to prove a point. The posting wants fluency in the standard tools.

## Phases

Nine phases, each one to two weeks. Each has what you build, what you have to learn to build it, and a done-when test that is observable, not a feeling. Do them in order. Phase 1 before any code, because the habit of deploying to the box from the first commit is the skill.

### Phase 0: Repo and working method (2 to 3 days)

Build: a GitHub repo with a CLAUDE.md, a docs folder with this brief as 00-brief.md, a .gitignore, a Makefile or justfile, and a README that is empty except for the architecture sketch.

Learn: nothing new. Set up the Claude project and the Claude Code workflow the same way as peers.

Done when: the repo exists, CLAUDE.md states the stack and the rules, and the first brief for phase 1 is written.

### Phase 1: Linux box (1 week)

Build: a VPS you can ssh into with keys only, a non-root user with sudo, ufw firewall with only 22, 80 and 443 open, fail2ban, unattended security updates, Docker installed from Docker's repo, a systemd unit that will later run the compose stack, nginx with a TLS certificate from Let's Encrypt on a cheap domain or a free subdomain.

Learn: ssh and key management, users and groups, systemd units and journalctl, ufw, package management, where logs live, how to read top and df and free, how to recover when you lock yourself out (the VPS console).

Done when: a hello-world container is reachable at https://your-domain, survives a reboot of the box without you touching it, and you can explain every line of the nginx config.

### Phase 2: Feed and book (2 weeks)

Build: an asyncio service that subscribes to the exchange websocket, parses trades and book-top messages into typed records, handles reconnect with backoff, detects sequence gaps, and writes ticks to Postgres and the latest price per instrument to Redis. A positions table in Postgres and a loader. A FastAPI app with GET endpoints for positions and latest prices.

Learn: asyncio properly (tasks, queues, cancellation, backpressure), websockets client, Postgres from Python (asyncpg or psycopg3), schema migrations (alembic or plain SQL files), Redis basics (SET, HSET, PUBLISH), FastAPI, pydantic models.

Done when: the feed runs on the box for 24 hours in Docker Compose with no manual restarts, every reconnect is logged, and the tick table has no gaps longer than the reconnect time. Tests cover the parser and the gap detector with recorded messages.

### Phase 3: Risk engine (2 weeks)

Build: a calc service that reads ticks from Redis pub/sub, maintains the book in memory, and on every tick recomputes per-position and total PnL, high and low water marks, rolling realised vol, and on a one-minute timer parametric VaR, historical VaR from the stored ticks, the price shock grid, and delta and gamma for the perps. Per tick, cheap microstructure measures from book-top and trades: spread, microprice, and trade-flow imbalance over a rolling window. A daily VaR backtest: count breaches against the forecast and run a Kupiec proportion-of-failures test. Writes current state to Redis as one JSON document and one-minute snapshots to Postgres. A websocket endpoint on the API that pushes the state document to any connected browser.

Learn: this is where the quant work goes, but the engineering lesson is state management under a stream: what is recomputed on every tick, what on a timer, how to keep the hot path under a millisecond, how to measure that, and what happens when the feed stalls.

Done when: the state document updates within 50 ms of a tick on the box, measured and logged. VaR matches a pandas calculation on the same stored ticks to four decimals. A feed stall sets a stale flag inside 5 seconds. Load test: replay a recorded hour at 10x speed without the queue growing. After a week of stored ticks the VaR backtest report shows the breach count, the expected count and the Kupiec p-value.

### Phase 3b: Options sleeve (1.5 to 2 weeks)

Build: subscribe to Deribit option tickers for one underlying (BTC), two or three expiries, strikes within about 20 percent of the forward. Add three to six paper option positions to the book. A Black-76 pricer off the exchange forward, implied vol from mid by Newton with a bisection fallback, a smile fit per expiry (raw SVI, with a quadratic in log-moneyness as the fallback), and delta, gamma, vega and theta per position. Option PnL joins the book, vega by expiry joins the state document, and the shock grid gains a vol axis for the options. Every minute, compare your own IV and fitted smile to Deribit's mark IV and log the residuals per strike.

Learn: Black-76 and why Deribit options are inverse (quoted and settled in BTC, so price and greeks need converting), root finding that does not blow up on deep wings, what makes a smile arbitrage-free (butterfly and calendar), how greeks misbehave near expiry, and where the pricing work belongs on the hot path versus the timer.

Done when: your pricer reproduces Deribit's mark price from its mark IV to within 0.1 percent across the sleeve; your IV from mid is within 0.5 vol points of mark IV for the liquid strikes; tests cover the pricer against textbook values, the IV solver on wings and near expiry, and a no-butterfly-arbitrage check on the fitted smile, all with recorded messages; and phase 3's 50 ms state latency still holds with the sleeve on.

### Phase 4: React dashboard (2 to 3 weeks)

Build: a Vite and TypeScript React app with a websocket hook that subscribes to the state stream. Components: PnL tiles, positions table (sortable, editable entry price and size with a PUT back to the API), a live price and PnL chart, the VaR line with its limit, the shock grid as a heat-coloured table, the options greeks in the positions table and a smile chart per expiry (your fit against mark IV), an alerts panel, a connection status indicator. Served by nginx from the same box.

Learn: React fundamentals (components, props, state, effects, custom hooks), TypeScript types for the API contract, how to keep a chart at 60 fps when data arrives 20 times a second (throttle, requestAnimationFrame), a build pipeline, CSS enough to lay out a dashboard. This is the biggest learning phase and the one to be patient with.

Done when: the dashboard updates live in a browser on your phone over the public URL, an edited position shows its new PnL within one tick, and a Playwright test loads the page and sees a PnL tile populate.

### Phase 5: Alerts and replay (1 week)

Build: an alert rules table (metric, threshold, direction, cooldown), an evaluator in the calc service, delivery to the dashboard and a Slack or Discord webhook, an alerts history table. A replay mode that plays back stored ticks for a chosen hour at chosen speed through the same pipeline.

Learn: idempotent alerting with cooldowns, webhooks, and the value of a replay path for debugging a live system.

Done when: a limit breach reaches your phone within 10 seconds, does not repeat inside the cooldown, and a replayed hour reproduces the same alerts as the live run did.

### Phase 6: CI/CD and observability (2 weeks)

Build: GitHub Actions on every push runs ruff, mypy, pytest, the front-end type check and build, and builds the images. On merge to main it pushes images to GHCR and deploys to the box over ssh with a health check and a rollback if the check fails. Prometheus metrics from the feed and calc services (ticks per second, parse errors, reconnects, calc latency histogram, queue depth, websocket clients). Prometheus and Grafana containers, one Grafana dashboard for the system, alertmanager rule for feed down. Structured JSON logs shipped to journald, with a documented way to search them.

Learn: GitHub Actions syntax and secrets, image registries, zero-downtime restarts in compose, the Prometheus data model and PromQL, Grafana panels, what to alert on and what to only graph.

Done when: a commit to main reaches production with no manual step and a deliberately broken commit is rolled back automatically. The Grafana dashboard shows the calc latency histogram, and you can answer "what happened at 03:14 last night" from Grafana and the logs without ssh.

### Phase 7: LLM assistant and evals (2 weeks)

Build: an assistant endpoint using the Anthropic API with tool use. Tools are your own API: get\_positions, get\_state, get\_snapshots(from, to), get\_alerts(from, to), get\_pnl\_attribution(from, to), get\_vol\_surface(expiry). The assistant answers questions like "why is PnL down since 09:30" or "which position drives VaR" by calling tools, and shows its tool calls in the dashboard. An eval set of 30 to 50 questions with known answers from recorded states, a pytest harness that runs them against the live assistant, scores them (exact for numbers, rubric for prose), and reports a pass rate. A CI job that runs the evals on a schedule and graphs the pass rate.

Learn: tool schemas, the tool-use loop, system prompt design, keeping the model from inventing numbers it did not fetch, eval design, cost and latency tracking per call.

Done when: the eval pass rate is above 90 percent, every number in an answer is traceable to a tool result, and the write-up includes one case the model got wrong and what you changed to fix it.

### Phase 8: Write-up (3 to 4 days)

Build: the README as the architecture document with a diagram, the operations runbook, a short post on three things that broke in production and how you found them, and the eval results. Record a two-minute screen capture of the dashboard during a volatile hour.

Done when: someone who has never seen the repo can run it locally from the README in under 15 minutes, and the post reads like a risk developer wrote it.

## Working method

Same split as the peers build, which already works. A Claude project holds this brief and the running notes and is where you think, review and write the next brief. Claude Code does the building against the repo. You review every output and write down what it got wrong.

- One brief per phase in docs/NN-phase.md, written in the Claude project before the Claude Code session starts. State the done-when test in the brief so the session builds toward it.
- CLAUDE.md carries the stack, the rules (tests for every service, no secrets in the repo, structured logs, every container has a health check), and the deployment steps. Update it when a rule changes.
- The session commits. You review the diff on GitHub, not in the terminal. Anything you reapply by hand goes in the notes.
- Two things to do yourself rather than delegate, because they are the skills: the Linux administration in phase 1, and the first React component in phase 4. Have Claude Code explain, then type it. After that, delegate as normal.
- Keep a running log in the Claude project of what broke in production and how you found it. That log becomes the phase 8 post and the interview answers.
- The difference from the work setup: one machine, real .py files, git push to GitHub, no bundler. Enjoy it.

## Scope guards

The project fails by growing. Each of these is tempting and each is out.

- No real money, no exchange API keys with trading permission, no order placement. Paper positions only.
- No Kubernetes, Terraform or Ansible. Compose on one box is the whole deployment. If the project is done and you want the plus, add Ansible for the box setup as a phase 9.
- One exchange, five underlyings at most. Options on one underlying only, two or three expiries. More feeds is more of the same.
- Options stop at phase 3b: Black-76, one smile model per expiry, first-order greeks plus gamma. No local or stochastic vol, no exotics, no strategy or market-making simulation, no option order book replay.
- No authentication beyond basic auth on nginx. User management is a different project.
- No mobile app. The dashboard is responsive, that is enough.
- No second front end framework and no component library bake-off. Pick one chart library in phase 4 and keep it.
- Do not rewrite the risk engine in Rust or Go. Python with measured latency is the posting's requirement.
- Do not start phase 4 before the done-when tests for phases 3 and 3b pass. The front end on a flaky backend teaches nothing.

## Talking about it

Each phase produces an answer to a question this kind of interview asks. Write the answer down when the phase ends, while the details are fresh.

| Interview question | Phase | The answer you will have |
| --- | --- | --- |
| Walk me through a system you built end to end | All | The architecture diagram and the data path from exchange to browser, with numbers: ticks per second, calc latency, deploy time |
| How do you handle a feed going down during market hours | 2, 5 | Reconnect with backoff, gap detection, stale flag, alert to phone inside 10 seconds, the replay path for the post-mortem |
| What is on the hot path and how did you keep it fast | 3 | What recomputes per tick, what on a timer, the latency histogram, the 10x replay load test |
| Tell me about your deployment pipeline | 6 | Push to main, CI, image build, ssh deploy, health check, automatic rollback, and the time a broken commit rolled back |
| How do you know the system is healthy at 3 am | 6 | The Grafana dashboard, what you alert on and what you only graph, where the logs are |
| How do you price options and know the model is right | 3b | Black-76 on an inverse venue, the smile fit, residuals against the exchange's mark IV, and the strike where the fit went wrong |
| What did you build with React | 4 | A live dashboard at 20 updates a second without dropping frames, the websocket hook, the editable position table |
| How have you integrated an LLM into an application | 7 | Tool calling against your own API, the eval set, the pass rate graph, the case the model got wrong |
| How do you use AI coding tools and what goes wrong | 0, all | The brief and review loop, the mistakes you caught in the log, the two things you did by hand and why |
| Something that broke in production and what you did | 8 | Three stories from the log, each with how you found it and what changed |
| Why should a risk team hire you to build this | Your background | You have been the user of these systems for 17 years and you know what the risk analyst at 7 am needs to see first |
