# Notes

What broke, how it was found, what changed. Newest first.

| Date | Phase | What happened | How found | What changed |
| --- | --- | --- | --- | --- |
| 2026-10-25 | 1 | First ssh login to the new droplet fell back to a password prompt and was refused | `ssh -v` and `ls $HOME\.ssh` showed the PC was offering the right key, so the droplet never got it at creation. A paste of the key into the web console didn't take either | Set a temporary root password from the web console, piped the .pub file over ssh into /root/.ssh/authorized_keys. Lesson: DigitalOcean installs keys only at creation, so check the key is ticked; PowerShell doesn't expand `~` for ssh-keygen, use `$HOME` |
