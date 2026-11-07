# NSA TOOLKIT

**500+ Bug Bounty & VAPT Tools Installer**

One command. Every tool. Zero errors.

Made by [BLOODRAVENIST](https://github.com/BLOODRAVENIST)

## Quick Start

    git clone https://github.com/BLOODRAVENIST/nsa-tools-installer.git
    cd nsa-tools-installer
    bash install.sh
    source ~/.bashrc
    bash verify.sh

## What Gets Installed

- Kali metapackages (20) — info-gathering, vulnerability, web, exploitation
- Apt security tools (80+) — nmap, nikto, sqlmap, hydra, hashcat, gobuster, ffuf
- Go tools (40+) — subfinder, httpx, nuclei, katana, dnsx, naabu, dalfox
- Pipx tools (25+) — arjun, ghauri, dirsearch, semgrep, ssrfmap, xsstrike
- Git repos (35+) — SecLists, PayloadsAllTheThings, XSStrike, tplmap
- Nuclei templates (10,000+) — CVE, exposures, misconfigurations
- Wordlists (1,000+) — SecLists complete collection

**Total: ~350 unique binaries, 10,000+ attack techniques**

## Features

- Idempotent — safe to re-run, skips installed tools
- Graceful — one failed tool doesn't stop script
- Verified — full green/red report at end
- Logged — everything to ~/nsa_install_*.log
- PATH auto-fix — persists to .bashrc / .zshrc
- Go auto-install — downloads Go if missing
- Zero dependencies — fresh Kali / Debian ready

## Requirements

- Kali Linux / Debian 11+ / Ubuntu 20.04+
- 15 GB free disk
- 2 GB RAM
- sudo access
- Stable internet (~3 GB download)

## Usage Examples

    subfinder -d target.com -all | httpx -silent | nuclei -silent

    ffuf -u https://target.com/FUZZ -w /usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt

    sqlmap -u "https://target.com/?id=1" --batch --dbs

    dalfox url "https://target.com/?q=test"

## Legal

Authorized security testing only.

- Bug bounty programs with valid scope
- Systems you own
- Written permission from owner
- Lab environments (HTB, THM, PortSwigger)

Never test without permission — illegal under CFAA, CMA, IT Act.

## License

MIT License — see [LICENSE](LICENSE)

## Star this repo

If this helped you, drop a star.

Built for hunters, by hunters.
