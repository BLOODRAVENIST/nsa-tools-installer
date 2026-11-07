#!/usr/bin/env bash
GRN=$'\033[1;32m'; YLW=$'\033[1;33m'; RED=$'\033[1;31m'
CYN=$'\033[1;36m'; WHT=$'\033[1;37m'; RST=$'\033[0m'
have() { command -v "$1" >/dev/null 2>&1; }
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"

declare -A CAT
CAT["RECON"]="subfinder assetfinder amass dnsx shuffledns alterx asnmap chaos uncover massdns"
CAT["HTTP"]="httpx httprobe whatweb wafw00f cdncheck tlsx"
CAT["URL"]="katana waybackurls gau hakrawler anew unfurl gf gron qsreplace meg"
CAT["DIR"]="ffuf gobuster dirb wfuzz feroxbuster dirsearch dirbuster"
CAT["PORT"]="nmap naabu masscan"
CAT["VULN"]="nuclei sqlmap ghauri dalfox xsstrike commix subjack nikto"
CAT["API"]="arjun paramspider"
CAT["CLOUD"]="cloudlist interactsh-client mapcidr"
CAT["PASS"]="hydra john hashcat medusa patator ncrack"
CAT["SSL"]="sslscan sslyze"
CAT["C2"]="crackmapexec netexec responder bettercap"
CAT["SCREENSHOT"]="gowitness"
CAT["SECRETS"]="trufflehog gitleaks semgrep"
CAT["OSINT"]="theHarvester h8mail holehe sherlock maigret"
CAT["SYS"]="curl wget git python3 ruby perl java"

T=0; F=0; M=()
clear
printf "\n${GRN}=== NSA TOOLKIT VERIFY ===${RST}\n"
for cat in RECON HTTP URL DIR PORT VULN API CLOUD PASS SSL C2 SCREENSHOT SECRETS OSINT SYS; do
    printf "\n${CYN}--- %s ---${RST}\n" "$cat"
    for tool in ${CAT[$cat]}; do
        ((T++))
        if have "$tool"; then ((F++)); printf "  ${GRN}[v]${RST} %-20s ${WHT}%s${RST}\n" "$tool" "$(command -v "$tool")"
        else M+=("$tool"); printf "  ${RED}[x]${RST} %-20s ${RED}MISSING${RST}\n" "$tool"; fi
    done
done
echo ""
printf "${GRN}=== SUMMARY ===${RST}\n"
printf "  Checked: %d | ${GRN}Found: %d${RST} | ${YLW}Missing: %d${RST}\n" "$T" "$F" "${#M[@]}"
PCT=$(( F * 100 / T ))
if [ $PCT -ge 90 ]; then printf "  ${GRN}%d%% READY TO HUNT${RST}\n" "$PCT"
elif [ $PCT -ge 70 ]; then printf "  ${YLW}%d%% MOSTLY READY${RST}\n" "$PCT"
else printf "  ${RED}%d%% RUN install.sh${RST}\n" "$PCT"; fi
if [ ${#M[@]} -gt 0 ]; then
    echo ""
    printf "${YLW}  Missing:${RST}\n"
    for m in "${M[@]}"; do printf "    - %s\n" "$m"; done
fi
echo ""
