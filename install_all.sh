#!/usr/bin/env bash
# NSA Bug Bounty — Universal Installer
# by BLOODRAVENIST
set -o pipefail
LOG="$HOME/nsa_install_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

GRN=$'\033[1;32m'; YLW=$'\033[1;33m'; RED=$'\033[1;31m'; CYN=$'\033[1;36m'; RST=$'\033[0m'
info() { printf "\n${CYN}[*] %s${RST}\n" "$*"; }
ok()   { printf "${GRN}[+] %s${RST}\n" "$*"; }
warn() { printf "${YLW}[!] %s${RST}\n" "$*"; }
fail() { printf "${RED}[x] %s${RST}\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

info "Starting $(date)"
info "Log: $LOG"

# STEP 1: Exit venv
[ -n "$VIRTUAL_ENV" ] && unset VIRTUAL_ENV PYTHONHOME PYTHONPATH

# STEP 2: FIX PATH (critical)
info "STEP 1 — Fix PATH"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    touch "$rc"
    grep -q "NSA_FRAMEWORK_PATH" "$rc" 2>/dev/null || {
        echo "" >> "$rc"
        echo "# NSA_FRAMEWORK_PATH" >> "$rc"
        echo 'export GOPATH=$HOME/go' >> "$rc"
        echo 'export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"' >> "$rc"
    }
done
have whoami || { fail "whoami missing — abort"; exit 1; }
ok "PATH fixed"

# STEP 3: sudo
SUDO=""
[ "$EUID" -ne 0 ] && { have sudo && SUDO="sudo" || { fail "no sudo"; exit 1; }; }

# STEP 4: base deps
info "STEP 2 — Base packages"
$SUDO apt-get update -qq 2>/dev/null || warn "apt update failed"
BASE=(curl wget git build-essential make python3 python3-pip python3-venv python3-dev pipx jq unzip xz-utils ca-certificates dnsutils whois net-tools netcat-openbsd socat nmap nikto masscan ruby ruby-dev perl openjdk-17-jdk chromium)
$SUDO apt-get install -y -qq --no-install-recommends "${BASE[@]}" 2>/dev/null || warn "some base pkgs skipped"
ok "Base done"

# STEP 5: pipx
info "STEP 3 — pipx"
python3 -m pipx ensurepath 2>/dev/null || true
export PATH="$HOME/.local/bin:$PATH"

# STEP 6: Go
info "STEP 4 — Go"
if ! have go; then
    GO_VER="1.22.5"
    TMP=$(mktemp -d)
    if wget -q "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" -O "$TMP/go.tgz"; then
        $SUDO rm -rf /usr/local/go
        $SUDO tar -C /usr/local -xzf "$TMP/go.tgz"
        rm -rf "$TMP"
        export PATH="/usr/local/go/bin:$PATH"
        ok "Go installed"
    else fail "Go download failed"; fi
else ok "Go present"; fi
export GOPATH="$HOME/go"; export PATH="$GOPATH/bin:/usr/local/go/bin:$PATH"; mkdir -p "$GOPATH/bin"

# STEP 7: apt security
info "STEP 5 — Security tools via apt"
SEC=(gobuster ffuf dirb wfuzz feroxbuster sqlmap commix hydra john hashcat medusa patator whatweb wafw00f dnsrecon dnsenum fierce dnsmap sslscan exploitdb seclists wordlists sqlite3 default-mysql-client postgresql-client redis-tools smbclient smbmap ldap-utils snmp hping3 tcpdump tshark aircrack-ng responder crackmapexec enum4linux gdb binwalk radare2 strace ltrace proxychains4 tor)
$SUDO apt-get install -y -qq --no-install-recommends "${SEC[@]}" 2>/dev/null || warn "some apt sec tools skipped"
ok "apt sec done"

# STEP 8: Kali metapackages
info "STEP 6 — Kali metapackages (SLOW, 10-20 min)"
META=(kali-tools-information-gathering kali-tools-vulnerability kali-tools-web kali-tools-database kali-tools-passwords kali-tools-fuzzing kali-tools-exploitation kali-tools-forensics kali-tools-reporting)
for m in "${META[@]}"; do
    if dpkg -l "$m" 2>/dev/null | grep -q "^ii"; then ok "$m present"
    else info "Installing $m..."; $SUDO apt-get install -y -qq --no-install-recommends "$m" 2>/dev/null && ok "$m ok" || warn "$m failed"; fi
done
ok "Metapackages done"

# STEP 9: Go tools
info "STEP 7 — Go tools (50+, 10-15 min)"
GO_TOOLS=(
github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
github.com/projectdiscovery/httpx/cmd/httpx@latest
github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
github.com/projectdiscovery/katana/cmd/katana@latest
github.com/projectdiscovery/dnsx/cmd/dnsx@latest
github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
github.com/projectdiscovery/chaos-client/cmd/chaos@latest
github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
github.com/projectdiscovery/alterx/cmd/alterx@latest
github.com/projectdiscovery/asnmap/cmd/asnmap@latest
github.com/projectdiscovery/tlsx/cmd/tlsx@latest
github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest
github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
github.com/projectdiscovery/cloudlist/cmd/cloudlist@latest
github.com/projectdiscovery/uncover/cmd/uncover@latest
github.com/tomnomnom/assetfinder@latest
github.com/tomnomnom/waybackurls@latest
github.com/tomnomnom/httprobe@latest
github.com/tomnomnom/meg@latest
github.com/tomnomnom/anew@latest
github.com/tomnomnom/unfurl@latest
github.com/tomnomnom/gf@latest
github.com/tomnomnom/gron@latest
github.com/tomnomnom/qsreplace@latest
github.com/lc/gau/v2/cmd/gau@latest
github.com/ffuf/ffuf/v2@latest
github.com/OJ/gobuster/v3@latest
github.com/hahwul/dalfox/v2@latest
github.com/hakluke/hakrawler@latest
github.com/hakluke/hakcheckurl@latest
github.com/haccer/subjack@latest
github.com/LukaSikic/subzy@latest
github.com/sensepost/gowitness@latest
github.com/trufflesecurity/trufflehog/v3@latest
github.com/gitleaks/gitleaks/v8@latest
)
IG=0; FG=0
for tool in "${GO_TOOLS[@]}"; do
    name=$(basename "$tool" | sed 's/@.*//' | sed 's/v[0-9]*$//')
    if have "$name"; then ok "$name present"; ((IG++)); continue; fi
    info "go install $name..."
    if timeout 300 go install "$tool" 2>/dev/null; then ok "$name ok"; ((IG++)); else warn "$name FAILED"; ((FG++)); fi
done
ok "Go tools: $IG ok, $FG failed"

# STEP 10: pipx tools
info "STEP 8 — pipx tools (18 packages)"
PIPX_TOOLS=(arjun dirsearch ghauri paramspider waybackpy ssrfmap xsstrike semgrep bandit safety detect-secrets jwt-tool graphql-cop sslyze wapiti3 pwntools impacket)
IPX=0; FPX=0
for pkg in "${PIPX_TOOLS[@]}"; do
    if pipx list 2>/dev/null | grep -q "$pkg"; then ok "$pkg present"; ((IPX++)); continue; fi
    info "pipx install $pkg..."
    if timeout 300 pipx install "$pkg" 2>/dev/null; then ok "$pkg ok"; ((IPX++)); else warn "$pkg FAILED"; ((FPX++)); fi
done
ok "pipx: $IPX ok, $FPX failed"

# STEP 11: git clones
info "STEP 9 — Git clones (24 repos)"
TOOLS_DIR="$HOME/tools"; mkdir -p "$TOOLS_DIR"
GIT_TOOLS=(
"https://github.com/danielmiessler/SecLists.git|SecLists"
"https://github.com/swisskyrepo/PayloadsAllTheThings.git|PayloadsAllTheThings"
"https://github.com/projectdiscovery/nuclei-templates.git|nuclei-templates"
"https://github.com/s0md3v/XSStrike.git|XSStrike"
"https://github.com/GerbenJavado/LinkFinder.git|LinkFinder"
"https://github.com/m4ll0k/SecretFinder.git|SecretFinder"
"https://github.com/s0md3v/Photon.git|Photon"
"https://github.com/aboul3la/Sublist3r.git|Sublist3r"
"https://github.com/epinna/tplmap.git|tplmap"
"https://github.com/vladko312/SSTImap.git|SSTImap"
"https://github.com/s0md3v/Corsy.git|Corsy"
"https://github.com/chenjj/CORScanner.git|CORScanner"
"https://github.com/RhinoSecurityLabs/GCPBucketBrute.git|GCPBucketBrute"
"https://github.com/initstring/cloud_enum.git|cloud_enum"
"https://github.com/sa7mon/S3Scanner.git|S3Scanner"
"https://github.com/hisxo/gitGraber.git|gitGraber"
"https://github.com/internetwache/GitTools.git|GitTools"
"https://github.com/ticarpi/jwt_tool.git|jwt_tool"
"https://github.com/brendan-rius/c-jwt-cracker.git|c-jwt-cracker"
"https://github.com/dolevf/graphql-cop.git|graphql-cop"
"https://github.com/nikitastupin/clairvoyance.git|clairvoyance"
"https://github.com/jas502n/SSRFmap.git|SSRFmap"
"https://github.com/carlospolop/PEASS-ng.git|PEASS-ng"
"https://github.com/carlospolop/hacktricks|hacktricks"
)
IGIT=0; FGIT=0
for entry in "${GIT_TOOLS[@]}"; do
    url="${entry%%|*}"; dir="${entry##*|}"
    if [ -d "$TOOLS_DIR/$dir" ]; then ok "$dir present"; ((IGIT++)); continue; fi
    info "clone $dir..."
    if timeout 180 git clone --depth 1 "$url" "$TOOLS_DIR/$dir" 2>/dev/null; then ok "$dir ok"; ((IGIT++)); else warn "$dir FAILED"; ((FGIT++)); fi
done
ok "Git: $IGIT ok, $FGIT failed"

# STEP 12: Nuclei templates
info "STEP 10 — Nuclei templates"
have nuclei && { nuclei -update-templates 2>/dev/null && ok "templates updated" || warn "templates failed"; } || warn "nuclei missing"

# STEP 13: wordlist links
[ -d "/usr/share/seclists" ] && ln -sfn /usr/share/seclists "$HOME/tools/SecLists" 2>/dev/null
[ -d "$TOOLS_DIR/SecLists" ] && ln -sfn "$TOOLS_DIR/SecLists" "/usr/share/wordlists/seclists" 2>/dev/null

echo ""
echo "═══════════════════════════════════════════"
echo "  INSTALLATION COMPLETE"
echo "  Log: $LOG"
echo "═══════════════════════════════════════════"

# STEP 14: VERIFY
info "STEP 11 — VERIFY"
ALL=(nmap nikto curl wget git python3 ruby perl java subfinder httpx nuclei katana dnsx naabu chaos interactsh-client shuffledns alterx asnmap tlsx cdncheck mapcidr cloudlist uncover assetfinder waybackurls httprobe meg anew unfurl gf gron qsreplace gau whois dig host dnsrecon dnsenum fierce whatweb wafw00f ffuf gobuster dirb wfuzz feroxbuster dirsearch sqlmap ghauri dalfox xsstrike subjack subzy hakrawler hydra john hashcat medusa patator sslscan commix jq proxychains4 gowitness)
FOUND=0; MISS=()
for t in "${ALL[@]}"; do have "$t" && ((FOUND++)) || MISS+=("$t"); done
TOTAL=${#ALL[@]}
echo ""
echo "  ${GRN}VERIFICATION${RST}"
echo "  ────────────────────"
echo "  Total:   $TOTAL"
echo "  ${GRN}Found:   $FOUND${RST}"
echo "  ${YLW}Missing: ${#MISS[@]}${RST}"
[ ${#MISS[@]} -gt 0 ] && { echo ""; echo "  Missing:"; for m in "${MISS[@]}"; do printf "    ${YLW}x${RST} %s\n" "$m"; done; }

echo ""
echo "  FRAMEWORK TOOL CHECK"
echo "  ────────────────────"
FRAMEWORK=(nmap nikto gobuster ffuf subfinder httpx nuclei katana dnsx naabu sqlmap whatweb wafw00f dalfox hydra amass)
for t in "${FRAMEWORK[@]}"; do have "$t" && printf "  ${GRN}v${RST} %-15s %s\n" "$t" "$(command -v "$t")" || printf "  ${RED}x${RST} %-15s MISSING\n" "$t"; done

echo ""
echo "═══════════════════════════════════════════"
echo "  Go:      $IG ok, $FG failed"
echo "  pipx:    $IPX ok, $FPX failed"
echo "  Git:     $IGIT ok, $FGIT failed"
echo "  Binary:  $FOUND / $TOTAL"
echo "═══════════════════════════════════════════"
echo "  Restart shell or: source ~/.bashrc"
echo "  Then framework: cd ~/PROJECT/NSA_BUGHUNTING_FRAMEWORK && ./run.sh"
echo "═══════════════════════════════════════════"
