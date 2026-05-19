#!/usr/bin/env bash
# ============================================================
#  Student Dev Tools UNINSTALLER - macOS
#  Removes: Git, VS Code, JetBrains Toolbox, MySQL Server + Workbench
#
#  One-liner (run in Terminal):
#    bash <(curl -fsSL https://raw.githubusercontent.com/CruzSanchez/DayOneSetup/main/UninstallDevToolsMac.sh)
# ============================================================

set -uo pipefail

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${CYAN}  $1${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

print_ok()   { echo -e "  ${GREEN}[OK]${RESET}   $1"; }
print_skip() { echo -e "  ${YELLOW}[SKIP]${RESET} $1"; }
print_warn() { echo -e "  ${RED}[WARN]${RESET} $1"; }

command_exists()      { command -v "$1" &>/dev/null; }
brew_installed()      { brew list --formula "$1" &>/dev/null 2>&1; }
brew_cask_installed() { brew list --cask "$1" &>/dev/null 2>&1; }

brew_uninstall() {
    local name="$1" pkg="$2"
    print_header "Uninstalling $name"
    if brew_installed "$pkg"; then
        brew uninstall "$pkg" && print_ok "$name removed." || print_warn "$name may not have uninstalled cleanly."
    else
        print_skip "$name is not installed."
    fi
}

brew_cask_uninstall() {
    local name="$1" cask="$2"
    print_header "Uninstalling $name"
    if brew_cask_installed "$cask"; then
        brew uninstall --cask "$cask" && print_ok "$name removed." || print_warn "$name may not have uninstalled cleanly."
    else
        print_skip "$name is not installed."
    fi
}

# ── MySQL ─────────────────────────────────────────────────────

uninstall_mysql() {
    print_header "Uninstalling MySQL Server"

    if brew_installed "mysql"; then
        echo -e "  Stopping MySQL service..." 
        brew services stop mysql 2>/dev/null && print_ok "MySQL service stopped." || print_warn "Could not stop MySQL service."
        brew uninstall mysql && print_ok "MySQL Server removed." || print_warn "MySQL may not have uninstalled cleanly."
    else
        print_skip "MySQL Server is not installed."
    fi

    # Offer to remove leftover data directory
    local dataDir="/usr/local/var/mysql"
    # Also check Homebrew default on Apple Silicon
    [[ -d "/opt/homebrew/var/mysql" ]] && dataDir="/opt/homebrew/var/mysql"

    if [[ -d "$dataDir" ]]; then
        echo ""
        echo -e "  ${YELLOW}MySQL data directory found at: $dataDir${RESET}"
        echo -e "  ${YELLOW}This contains your databases. Delete it? (y/n): ${RESET}" && read -r confirm
        if [[ "$confirm" == "y" ]]; then
            rm -rf "$dataDir" && print_ok "MySQL data directory removed."
        else
            print_skip "MySQL data directory kept."
        fi
    fi
}

# ── Assert macOS ─────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is for macOS only. Exiting."
    exit 1
fi

if ! command_exists brew; then
    echo -e "${RED}Homebrew not found — nothing to uninstall via brew.${RESET}"
    exit 1
fi

# ── Confirm ───────────────────────────────────────────────────

clear
echo ""
echo -e "${RED}  ╔══════════════════════════════════════════════╗${RESET}"
echo -e "${RED}  ║     Student Dev Tools UNINSTALLER (macOS)    ║${RESET}"
echo -e "${RED}  ║  Git | VS Code | JetBrains | MySQL           ║${RESET}"
echo -e "${RED}  ╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${YELLOW}This will uninstall all student dev tools from this machine.${RESET}"
echo -e "  ${YELLOW}Are you sure you want to continue? (y/n): ${RESET}" && read -r confirm

if [[ "$confirm" != "y" ]]; then
    echo ""
    echo -e "  Uninstall cancelled."
    exit 0
fi

# ── Uninstall (reverse install order) ────────────────────────

brew_cask_uninstall  "MySQL Workbench"   "mysqlworkbench"
uninstall_mysql
brew_cask_uninstall  "JetBrains Toolbox" "jetbrains-toolbox"
brew_cask_uninstall  "Visual Studio Code" "visual-studio-code"
brew_uninstall       "Git"               "git"

# Clean up 'code' symlink if present
print_header "Cleaning up shell commands"
if [[ -L "/usr/local/bin/code" ]]; then
    rm /usr/local/bin/code && print_ok "'code' symlink removed."
else
    print_skip "No 'code' symlink found."
fi

# ── Done ─────────────────────────────────────────────────────
print_header "Uninstall Complete"
echo ""
echo -e "  ${BOLD}All dev tools have been removed.${RESET}"
echo -e "  ${YELLOW}Restart your terminal for PATH changes to take effect.${RESET}"
echo ""
