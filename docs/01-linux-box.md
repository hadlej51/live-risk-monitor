# Phase 1: Linux box

Target: weeks of Oct 26 and Nov 2, 2026. Clay does this phase by hand. Claude explains and reviews; it does not hand over commands to paste.

## Goal

A VPS you administer, hardened, with Docker and nginx serving a hello-world container over HTTPS, that comes back by itself after a reboot. Every later phase deploys here.

## Done when

All of these are true, and you can show each one:

1. `ssh root@box` and password logins are refused; `ssh you@box` with your key works.
2. `sudo ufw status` shows only 22, 80 and 443 open.
3. fail2ban is running and `fail2ban-client status sshd` shows the jail.
4. Unattended security upgrades are enabled.
5. `https://your-domain` serves the hello-world container with a valid Let's Encrypt certificate, and port 80 redirects to it.
6. After `sudo reboot`, step 5 works again without you logging in.
7. You can explain every line of the nginx config and the systemd unit out loud.

## Before you start

- A VPS: Ubuntu 24.04 LTS, the smallest plan (Hetzner CX22 or a $6 DigitalOcean droplet). Add your ssh public key when you create it.
- A domain or free subdomain pointing an A record at the box's IP. DNS must resolve before the certificate step.
- Find the provider's web console now, before you need it. It's how you get back in if you lock yourself out.

## Steps

Do them in this order. After each one, check it worked before moving on, and note anything that surprised you in `docs/notes.md`.

1. **First login and updates.** Log in as root with your key, update the package lists and upgrade.
   Learn: apt, where packages come from, `/var/log/apt/`.
2. **Your user.** Create a non-root user, add it to the sudo group, copy your key to its `~/.ssh/authorized_keys` with the right permissions. Open a second terminal and confirm you can log in as that user and run sudo *before* changing anything else.
   Learn: users and groups, `/etc/passwd`, `/etc/group`, why `~/.ssh` permissions matter.
3. **Lock down ssh.** In sshd config, turn off root login and password authentication. Restart sshd while your existing session stays open, then test a new login.
   Learn: `/etc/ssh/sshd_config` and its `.d` directory, `systemctl`, `journalctl -u ssh`.
4. **Firewall.** Allow 22, 80 and 443 with ufw, then enable it. Allow 22 first.
   Learn: default policies, what ufw writes underneath (iptables/nftables), how Docker can bypass ufw for published ports and why that matters later.
5. **fail2ban.** Install it and enable the sshd jail.
   Learn: `jail.local` vs `jail.conf`, reading `/var/log/auth.log`.
6. **Unattended upgrades.** Install and enable security-only automatic updates.
   Learn: `/etc/apt/apt.conf.d/`, how to tell if a reboot is pending (`/var/run/reboot-required`).
7. **Docker.** Install Docker Engine and the compose plugin from Docker's own apt repository, not Ubuntu's. Add your user to the docker group and understand what that grants.
   Learn: apt repositories and signing keys, `docker run`, `docker ps`, `docker compose`.
8. **Hello world.** Write a `compose.yaml` with one small web container listening only on `127.0.0.1:8080`, with a health check and `restart: unless-stopped`.
   Learn: why bind to localhost and let nginx face the internet.
9. **systemd unit.** Write a unit that runs `docker compose up -d` for the project directory at boot and `down` on stop. Enable it.
   Learn: unit files, `After=`/`Requires=` on docker.service, `systemctl enable` vs `start`, `journalctl -u <unit>`.
10. **nginx and TLS.** Install nginx, write a server block that proxies to `127.0.0.1:8080`, get a certificate with certbot, confirm the HTTP to HTTPS redirect and auto-renewal (`certbot renew --dry-run`).
    Learn: server blocks, `proxy_pass` and the headers it should set, `nginx -t`, where nginx logs live.
11. **Reboot test.** `sudo reboot`, wait, load the site from your phone on mobile data.
12. **Look around.** Run `top`, `free -h`, `df -h`, `ss -tlnp`, `systemctl --failed` and know what each tells you.

## Lockout drill

Once everything works, deliberately break ssh (e.g. a bad sshd config line), get back in through the provider console, and fix it. Ten minutes now saves an evening later.

## What goes in the repo

- `deploy/nginx/live-risk-monitor.conf`, the server block
- `deploy/systemd/live-risk-monitor.service`, the unit
- `compose.yaml` with the hello-world service
- `docs/runbook.md`, a short section on how the box is set up and how to get back in

Not in the repo: your IP, your username, keys, or anything from `/etc` beyond the two files above.

## Review

When you're done, tell Claude and paste (or commit) the nginx config, the unit file and the output of the done-when checks. Claude reviews them against this brief and asks you to explain any line you can't.
