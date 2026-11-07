#!/usr/bin/env bash
# NSA TOOLKIT INSTALLER — BLOODRAVENIST
set +e
set -u
LOG="$HOME/nsa_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

GRN=$'\033[1;32m'; YLW=$'\033[1;33m'; RED=$'\033[1;31m'
CYN=$'\033[1;36m'; MAG=$'\033[1;35m'; WHT=$'\033[1;37m'; RST=$'\033[0m'
info() { printf "\n${CYN}[*] %s${RST}\n" "$*"; }
ok()   { printf "${GRN}[+] %s${RST}\n" "$*"; }
warn() { printf "${YLW}[!] %s${RST}\n" "$*"; }
fail() { printf "${RED}[x] %s${RST}\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

clear
printf "\n${GRN}"
echo "=============================================================="
echo "         NSA TOOLKIT INSTALLER — BLOODRAVENIST               "
echo "          Full Bug Bounty & VAPT Toolchain                    "
echo "=============================================================="
printf "${RST}\n"

info "STEP 1 / 12 — Fix PATH"
export GOPATH="$HOME/go"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    touch "$rc" 2>/dev/null
    grep -q "NSA_FRAMEWORK_PATH" "$rc" 2>/dev/null || {
        printf '\n# NSA_FRAMEWORK_PATH\nexport GOPATH=$HOME/go\nexport PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"\n' >> "$rc"
    }
done
have whoami || { fail "whoami missing — abort"; exit 1; }
ok "PATH fixed"

info "STEP 2 / 12 — Sudo check"
if [ "$EUID" -eq 0 ]; then SUDO=""; ok "running as root"
elif have sudo; then SUDO="sudo"; ok "sudo available"
else fail "no sudo"; exit 1; fi

info "STEP 3 / 12 — Base packages"
BASE=(curl wget git build-essential make gcc g++ python3 python3-pip python3-venv python3-dev pipx jq unzip xz-utils ca-certificates dnsutils whois net-tools netcat-openbsd socat ruby ruby-dev perl openjdk-17-jdk chromium sqlite3 pkg-config libssl-dev libffi-dev libpcap-dev nmap nikto masscan)
$SUDO apt-get update -qq 2>/dev/null || warn "apt update failed"
$SUDO apt-get install -y -qq --no-install-recommends "${BASE[@]}" 2>/dev/null || warn "some base pkgs skipped"
ok "base packages done"

info "STEP 3b — pipx ensurepath"
python3 -m pipx ensurepath >/dev/null 2>&1 || true
export PATH="$HOME/.local/bin:$PATH"
ok "pipx configured"

info "STEP 4 / 12 — Go compiler"
if ! have go; then
    TMP=$(mktemp -d); GV="1.22.5"
    info "Downloading Go $GV..."
    if wget -q "https://go.dev/dl/go${GV}.linux-amd64.tar.gz" -O "$TMP/g.tgz"; then
        $SUDO rm -rf /usr/local/go
        $SUDO tar -C /usr/local -xzf "$TMP/g.tgz"; rm -rf "$TMP"
        export PATH="/usr/local/go/bin:$PATH"
        ok "Go $GV installed"
    else fail "Go download failed"; fi
else ok "Go present: $(go version | awk '{print $3}')"; fi
mkdir -p "$GOPATH/bin"

info "STEP 5 / 12 — Kali metapackages (20 pkgs)"
META=(kali-tools-information-gathering kali-tools-vulnerability kali-tools-web kali-tools-database kali-tools-passwords kali-tools-fuzzing kali-tools-exploitation kali-tools-forensics kali-tools-reporting kali-tools-sniffing-spoofing kali-tools-reverse-engineering kali-tools-wireless kali-tools-hardware kali-tools-crypto-steganography kali-tools-802-11 kali-tools-windows-resources kali-tools-social-engineering kali-tools-post-exploitation kali-tools-top10 kali-tools-identify)
INST_META=()
for m in "${META[@]}"; do
    dpkg -l "$m" 2>/dev/null | grep -q "^ii" || INST_META+=("$m")
done
if [ ${#INST_META[@]} -gt 0 ]; then
    info "Installing ${#INST_META[@]} metapackages (SLOW, 5-15 min)..."
    $SUDO apt-get install -y -qq --no-install-recommends "${INST_META[@]}" 2>/dev/null || warn "some metapackages failed"
    ok "metapackages done"
else ok "all 20 metapackages present"; fi

info "STEP 6 / 12 — Security tools via apt"
SEC=(nmap nikto masscan sqlmap commix gobuster ffuf dirb wfuzz feroxbuster dirbuster hydra john hashcat medusa ncrack patator whatweb wafw00f sslscan dnsrecon dnsenum fierce dnsmap smbclient smbmap ldap-utils snmp hping3 tcpdump tshark aircrack-ng reaver bettercap ettercap-text-only gdb binwalk radare2 strace ltrace proxychains4 tor crackmapexec bloodhound neo4j impacket-scripts beef-xss metasploit-framework set routersploit sqlsus exploitdb seclists wordlists wpscan joomscan droopescan skipfish xsser zaproxy openvas faraday wireshark arp-scan dsniff tcpflow sslsplit mitmproxy gobuster sipvicious sipcrack responder）
# remove typo (）as chinese paren
SEC=(nmap nikto masscan sqlmap commix gobuster ffuf dirb wfuzz feroxbuster dirbuster hydra john hashcat medusa ncrack patator whatweb wafw00f sslscan dnsrecon dnsenum fierce dnsmap smbclient smbmap ldap-utils snmp hping3 tcpdump tshark aircrack-ng reaver bettercap ettercap-text-only gdb binwalk radare2 strace ltrace proxychains4 tor crackmapexec bloodhound neo4j impacket-scripts beef-xss metasploit-framework set routersploit sqlsus exploitdb seclists wordlists wpscan joomscan droopescan skipfish xsser zaproxy openvas faraday wireshark arp-scan dsniff tcpflow sslsplit mitmproxy sipvicious sipcrack responder gobuster)
$SUDO apt-get install -y -qq --no-install-recommends "${SEC[@]}" 2>/dev/null || warn "some sec tools skipped"
ok "apt security tools done"

info "STEP 7 / 12 — Go tools (40+, 10-15 min)"
GO_TOOLS=(
"subfinder|github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
"httpx|github.com/projectdiscovery/httpx/cmd/httpx@latest"
"nuclei|github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
"katana|github.com/projectdiscovery/katana/cmd/katana@latest"
"dnsx|github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
"naabu|github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
"chaos|github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
"interactsh-client|github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
"shuffledns|github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest"
"alterx|github.com/projectdiscovery/alterx/cmd/alterx@latest"
"asnmap|github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
"tlsx|github.com/projectdiscovery/tlsx/cmd/tlsx@latest"
"cdncheck|github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest"
"mapcidr|github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest"
"cloudlist|github.com/projectdiscovery/cloudlist/cmd/cloudlist@latest"
"uncover|github.com/projectdiscovery/uncover/cmd/uncover@latest"
"notify|github.com/projectdiscovery/notify/cmd/notify@latest"
"cvemap|github.com/projectdiscovery/cvemap/cmd/cvemap@latest"
"urlfinder|github.com/projectdiscovery/urlfinder/cmd/urlfinder@latest"
"assetfinder|github.com/tomnomnom/assetfinder@latest"
"waybackurls|github.com/tomnomnom/waybackurls@latest"
"httprobe|github.com/tomnomnom/httprobe@latest"
"meg|github.com/tomnomnom/meg@latest"
"anew|github.com/tomnomnom/anew@latest"
"unfurl|github.com/tomnomnom/unfurl@latest"
"gf|github.com/tomnomnom/gf@latest"
"gron|github.com/tomnomnom/gron@latest"
"qsreplace|github.com/tomnomnom/qsreplace@latest"
"gau|github.com/lc/gau/v2/cmd/gau@latest"
"ffuf|github.com/ffuf/ffuf/v2@latest"
"gobuster|github.com/OJ/gobuster/v3@latest"
"dalfox|github.com/hahwul/dalfox/v2@latest"
"hakrawler|github.com/hakluke/hakrawler@latest"
"hakcheckurl|github.com/hakluke/hakcheckurl@latest"
"hakip2host|github.com/hakluke/hakip2host@latest"
"hakoriginfinder|github.com/hakluke/hakoriginfinder@latest"
"subjack|github.com/haccer/subjack@latest"
"gowitness|github.com/sensepost/gowitness@latest"
"trufflehog|github.com/trufflesecurity/trufflehog/v3@latest"
"gitleaks|github.com/gitleaks/gitleaks/v8@latest"
)
IG=0; FG=0; SKIP=0
for entry in "${GO_TOOLS[@]}"; do
    name="${entry%%|*}"; path="${entry##*|}"
    if have "$name"; then ((SKIP++)); continue; fi
    info "go install $name"
    if timeout 120 go install "$path" >/dev/null 2>&1; then ((IG++)); ok "$name installed"
    else ((FG++)); warn "$name failed"; fi
done
ok "Go tools — $SKIP present, $IG new, $FG failed"

info "STEP 8 / 12 — pipx tools (25+)"
PIPX_TOOLS=(arjun paramspider dirsearch ghauri waybackpy ssrfmap xsstrike semgrep bandit safety detect-secrets graphql-cop sslyze wapiti3 pwntools impacket h8mail holehe sherlock-project maigret netexec mitmproxy shodan censys xxeserv)
IP=0; FP=0; SP=0
for pkg in "${PIPX_TOOLS[@]}"; do
    if pipx list 2>/dev/null | grep -qE "package $pkg "; then ((SP++)); continue; fi
    info "pipx install $pkg"
    if timeout 180 pipx install "$pkg" >/dev/null 2>&1; then ((IP++)); ok "$pkg installed"
    else ((FP++)); warn "$pkg failed"; fi
done
ok "pipx — $SP present, $IP new, $FP failed"

info "STEP 9 / 12 — Git repos (35+)"
TD="$HOME/tools"; mkdir -p "$TD"
GIT=(
"danielmiessler/SecLists|SecLists"
"swisskyrepo/PayloadsAllTheThings|PayloadsAllTheThings"
"projectdiscovery/nuclei-templates|nuclei-templates"
"fuzzdb-project/fuzzdb|fuzzdb"
"s0md3v/XSStrike|XSStrike"
"GerbenJavado/LinkFinder|LinkFinder"
"m4ll0k/SecretFinder|SecretFinder"
"s0md3v/Photon|Photon"
"aboul3la/Sublist3r|Sublist3r"
"epinna/tplmap|tplmap"
"vladko312/SSTImap|SSTImap"
"s0md3v/Corsy|Corsy"
"chenjj/CORScanner|CORScanner"
"RhinoSecurityLabs/GCPBucketBrute|GCPBucketBrute"
"initstring/cloud_enum|cloud_enum"
"hisxo/gitGraber|gitGraber"
"internetwache/GitTools|GitTools"
"ticarpi/jwt_tool|jwt_tool"
"jas502n/SSRFmap|SSRFmap"
"carlospolop/PEASS-ng|PEASS-ng"
"carlospolop/hacktricks|hacktricks"
"blacklanternsecurity/bbot|bbot"
"shmilylty/OneForAll|OneForAll"
"lanmaster53/recon-ng|recon-ng"
"smicallef/spiderfoot|spiderfoot"
"epinna/weevely3|weevely3"
"flozz/rivalcfg|rivalcfg"
"rbsec/sslscan|sslscan-git"
"nccgroup/ScoutSuite|ScoutSuite"
"prowler-cloud/prowler|prowler"
"NetSPI/MicroBurst|MicroBurst"
"RhinoSecurityLabs/pacu|pacu"
"ly4k/Certipy|Certipy"
"fortra/impacket|impacket-git"
"swisskyrepo/SSRFmap|SSRFmap-git"
"nomi-sec/PoC-in-GitHub|PoC-in-GitHub"
)
G_IG=0; G_SKIP=0; G_F=0
for entry in "${GIT[@]}"; do
    repo="${entry%%|*}"; dir="${entry##*|}"
    if [ -d "$TD/$dir" ]; then ((G_SKIP++)); continue; fi
    info "clone $dir"
    if timeout 180 git clone --depth 1 -q "https://github.com/$repo.git" "$TD/$dir" >/dev/null 2>&1; then
        ((G_IG++)); ok "$dir cloned"
    else ((G_F++)); warn "$dir failed"; fi
done
ok "git — $G_SKIP present, $G_IG new, $G_F failed"

info "STEP 10 / 12 — Nuclei templates"
if have nuclei; then
    nuclei -update-templates >/dev/null 2>&1 && ok "nuclei templates updated" || warn "templates failed"
else warn "nuclei not installed"; fi

info "STEP 11 / 12 — Symlinks"
[ -d "/usr/share/seclists" ] && ln -sfn /usr/share/seclists "$HOME/tools/SecLists" 2>/dev/null
[ -d "$TD/SecLists" ] && $SUDO ln -sfn "$TD/SecLists" "/usr/share/wordlists/seclists" 2>/dev/null
ok "symlinks created"

info "STEP 12 / 12 — Full verification"
ALL=(nmap nikto curl wget git python3 ruby perl java subfinder httpx nuclei katana dnsx naabu chaos interactsh-client shuffledns alterx asnmap tlsx cdncheck mapcidr cloudlist uncover assetfinder waybackurls httprobe meg anew unfurl gf gron qsreplace gau whois dig host dnsrecon dnsenum fierce whatweb wafw00f ffuf gobuster dirb wfuzz feroxbuster dirsearch sqlmap ghauri dalfox xsstrike subjack hydra john hashcat medusa patator sslscan commix proxychains4 gowitness trufflehog gitleaks semgrep arjun paramspider impacket-scripts crackmapexec metasploit-framework beef-xss zaproxy wpscan joomscan droopescan skipfish xsser responder bettercap aircrack-ng reaver smbclient smbmap ldapsearch snmpwalk hping3 tcpdump tshark gdb radare2 binwalk strace ltrace h8mail holehe sherlock maigret netexec)
FOUND=0; MISS=()
for t in "${ALL[@]}"; do
    if have "$t"; then ((FOUND++)); else MISS+=("$t"); fi
done

printf "\n${GRN}"
echo "=============================================================="
echo "           INSTALLATION COMPLETE                              "
echo "=============================================================="
printf "${RST}\n"
printf "  ${WHT}Total checked:    ${CYN}%d${RST}\n" "${#ALL[@]}"
printf "  ${WHT}Tools found:      ${GRN}%d${RST}\n" "$FOUND"
printf "  ${WHT}Tools missing:    ${YLW}%d${RST}\n" "${#MISS[@]}"
PCT=$(( FOUND * 100 / ${#ALL[@]} ))
printf "  ${WHT}Completion:       ${GRN}%d%%${RST}\n" "$PCT"
echo ""
printf "  ${WHT}go tools:   ${GRN}%d present${RST}, ${CYN}%d new${RST}, ${YLW}%d failed${RST}\n" "$SKIP" "$IG" "$FG"
printf "  ${WHT}pipx:       ${GRN}%d present${RST}, ${CYN}%d new${RST}, ${YLW}%d failed${RST}\n" "$SP" "$IP" "$FP"
printf "  ${WHT}git repos:  ${GRN}%d present${RST}, ${CYN}%d new${RST}, ${YLW}%d failed${RST}\n" "$G_SKIP" "$G_IG" "$G_F"

echo ""
printf "${CYN}  --- Critical Framework Tools ---${RST}\n"
CRIT=(nmap nikto gobuster ffuf subfinder httpx nuclei katana dnsx naabu sqlmap whatweb wafw00f dalfox hydra)
CRIT_MISS=0
for t in "${CRIT[@]}"; do
    if have "$t"; then printf "  ${GRN}[v]${RST} %-15s ${WHT}%s${RST}\n" "$t" "$(command -v "$t")"
    else printf "  ${RED}[x]${RST} %-15s ${RED}MISSING${RST}\n" "$t"; ((CRIT_MISS++)); fi
done

if [ ${#MISS[@]} -gt 0 ]; then
    echo ""
    printf "${YLW}  --- Missing (non-critical) ---${RST}\n"
    for m in "${MISS[@]}"; do printf "  ${YLW}[!]${RST} %s\n" "$m"; done
fi

echo ""
printf "${GRN}"
echo "=============================================================="
echo "  NEXT STEPS"
echo "  ---"
echo "  1. source ~/.bashrc"
echo "  2. bash verify.sh"
echo "  3. cd ~/PROJECT/NSA_BUGHUNTING_FRAMEWORK && ./run.sh"
echo "=============================================================="
printf "${RST}\n"
printf "${CYN}  Log: ${WHT}%s${RST}\n\n" "$LOG"
