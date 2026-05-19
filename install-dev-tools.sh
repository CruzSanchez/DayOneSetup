#!/usr/bin/env bash
# ============================================================
#  Student Dev Tools Installer - macOS
#  Installs: Homebrew, Git, VS Code, MySQL Server + Workbench
#  NOTE: Visual Studio full IDE is Windows-only.
#        VS Code + C# Dev Kit is the Mac equivalent.
#
#  One-liner (run in Terminal):
#    bash <(curl -fsSL https://raw.githubusercontent.com/CruzSanchez/DayOneSetup/main/DayOneSetupMac.sh)
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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
print_info() { echo -e "  ${BOLD}$1${RESET}"; }

command_exists() { command -v "$1" &>/dev/null; }

brew_installed()      { brew list --formula "$1" &>/dev/null; }
brew_cask_installed() { brew list --cask "$1" &>/dev/null; }

# ── Assert macOS ─────────────────────────────────────────────

if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is for macOS only. Exiting."
    exit 1
fi

# ── Homebrew ─────────────────────────────────────────────────

install_homebrew() {
    print_header "Checking Homebrew"

    if command_exists brew; then
        print_skip "Homebrew already installed. Updating..."
        brew update --quiet
        return
    fi

    print_info "Installing Homebrew (this may take a few minutes)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        grep -q "homebrew" "$HOME/.zprofile" 2>/dev/null || \
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi

    # Intel
    if [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_ok "Homebrew installed."
}

# ── Generic installers ────────────────────────────────────────

brew_install() {
    local name="$1" pkg="$2"
    print_header "Installing $name"
    if brew_installed "$pkg"; then
        print_skip "$name is already installed."
    else
        brew install "$pkg" && print_ok "$name installed." || print_warn "$name install may have failed."
    fi
}

brew_cask_install() {
    local name="$1" cask="$2"
    print_header "Installing $name"
    if brew_cask_installed "$cask"; then
        print_skip "$name is already installed."
    else
        brew install --cask "$cask" && print_ok "$name installed." || print_warn "$name install may have failed."
    fi
}

# ── MySQL ─────────────────────────────────────────────────────

install_mysql() {
    print_header "Installing MySQL Server"

    if brew_installed "mysql"; then
        print_skip "MySQL already installed."
    else
        brew install mysql && print_ok "MySQL installed." || { print_warn "MySQL install failed."; return; }
    fi

    print_info "Starting MySQL service..."
    brew services start mysql
    sleep 10

    print_info "Setting root password to 'password'..."
    mysql -u root --execute="
        ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
        FLUSH PRIVILEGES;
    " 2>/dev/null \
        && print_ok "Root password set." \
        || print_warn "Could not set root password automatically. Run manually:\n  mysql -u root\n  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
}

# ── VS Code shell command ─────────────────────────────────────

setup_vscode_shell() {
    print_header "Setting up 'code' shell command"
    if command_exists code; then
        print_skip "'code' command already available."
        return
    fi
    local bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if [[ -f "$bin" ]]; then
        ln -sf "$bin" /usr/local/bin/code 2>/dev/null && print_ok "'code' command linked." \
            || print_warn "Could not link 'code'. Open VS Code > Command Palette > 'Shell Command: Install code command'."
    else
        print_warn "VS Code not found at expected path. Open VS Code and install the shell command manually."
    fi
}

# ── Main ─────────────────────────────────────────────────────

clear
echo ""
echo -e "${MAGENTA}  ╔══════════════════════════════════════════════╗${RESET}"
echo -e "${MAGENTA}  ║     Student Dev Tools Installer (macOS)      ║${RESET}"
echo -e "${MAGENTA}  ║  Git | VS Code | JetBrains | MySQL           ║${RESET}"
echo -e "${MAGENTA}  ╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo "  Installing C# environment..."

install_homebrew

brew_install          "Git"                "git"
brew_cask_install     "Visual Studio Code" "visual-studio-code"
setup_vscode_shell
brew_cask_install     "JetBrains Toolbox"  "jetbrains-toolbox"
install_mysql
brew_cask_install     "MySQL Workbench"    "mysqlworkbench"

# ── Summary ───────────────────────────────────────────────────
print_header "Installation Complete"
echo ""
echo -e "  ${BOLD}Installed tools:${RESET}"
echo -e "  ${GREEN}•${RESET} Git                  $(git --version 2>/dev/null || echo 'restart terminal to verify')"
echo -e "  ${GREEN}•${RESET} Visual Studio Code   $(code --version 2>/dev/null | head -1 || echo 'restart terminal to verify')"
echo -e "  ${GREEN}•${RESET} JetBrains Toolbox    (open to install Rider)"
echo -e "  ${GREEN}•${RESET} MySQL Server         root pw: password"
echo -e "  ${GREEN}•${RESET} MySQL Workbench"
echo ""
echo -e "  ${YELLOW}Restart your computer before class.${RESET}"
echo ""
