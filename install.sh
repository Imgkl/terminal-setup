#!/bin/bash
set -e

# ============================================
# Terminal Setup — One-shot Mac bootstrap
# ============================================
# curl -fsSL https://raw.githubusercontent.com/Imgkl/terminal-setup/main/install.sh | bash
# Or: git clone ... && cd terminal-setup && bash install.sh

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

info()  { echo -e "${GREEN}[✓]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[✗]${RESET} $1"; }
step()  { echo -e "\n${BOLD}→ $1${RESET}"; }

# Determine script directory (works for both clone and curl|sh)
if [ -d "$(dirname "$0")/ghostty" ]; then
    DOTFILES="$(cd "$(dirname "$0")" && pwd)"
else
    # If run via curl|sh, clone the repo first
    DOTFILES="$HOME/.terminal-setup"
    if [ ! -d "$DOTFILES" ]; then
        step "Cloning terminal-setup repo..."
        git clone https://github.com/Imgkl/terminal-setup.git "$DOTFILES"
    fi
fi

echo -e "\n${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║    Terminal Setup — Mac Bootstrap    ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}\n"
echo -e "Source: ${BOLD}$DOTFILES${RESET}\n"

echo -e "${RED}${BOLD}⚠  WARNING:${RESET} This script is meant for fresh Mac setups."
echo -e "   It will ${BOLD}override${RESET} your existing .zshrc, starship.toml,"
echo -e "   and Ghostty config with symlinks to this repo."
echo -e "   (Existing files get a .bak backup, but that's about it.)"
echo -e ""
echo -e "   The developer did not give a fuck about writing logic"
echo -e "   to intelligently merge your existing configs. It just"
echo -e "   nukes and replaces. You've been warned.\n"

read -p "   Continue? [y/N] " confirm </dev/tty
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Aborted.${RESET}"
    exit 0
fi

# --------------------------------------------------
# 1. Homebrew
# --------------------------------------------------
step "Checking Homebrew..."
if command -v brew &>/dev/null; then
    info "Homebrew already installed"
else
    warn "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    info "Homebrew installed"
fi

# --------------------------------------------------
# 2. Brew packages
# --------------------------------------------------
step "Installing CLI tools via Homebrew..."
BREW_PACKAGES=(starship eza fd ripgrep bat fzf zoxide lazygit yazi ffmpeg sevenzip jq poppler resvg imagemagick fastfetch)

for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        info "$pkg already installed"
    else
        warn "Installing $pkg..."
        brew install "$pkg"
        info "$pkg installed"
    fi
done

# fuckoff (custom tap)
if brew list fuckoff &>/dev/null; then
    info "fuckoff already installed"
else
    warn "Installing fuckoff..."
    brew tap Imgkl/fuckoff && brew install fuckoff
    info "fuckoff installed"
fi

# --------------------------------------------------
# 3. Ghostty
# --------------------------------------------------
step "Checking Ghostty..."
if brew list --cask ghostty &>/dev/null || [ -d "/Applications/Ghostty.app" ]; then
    info "Ghostty already installed"
else
    warn "Installing Ghostty..."
    brew install --cask ghostty
    info "Ghostty installed"
fi

# --------------------------------------------------
# 3b. Cask packages
# --------------------------------------------------
step "Installing cask packages..."
BREW_CASKS=(font-symbols-only-nerd-font)

for cask in "${BREW_CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        info "$cask already installed"
    else
        warn "Installing $cask..."
        brew install --cask "$cask"
        info "$cask installed"
    fi
done

# --------------------------------------------------
# 4. Zsh plugins
# --------------------------------------------------
step "Setting up zsh plugins..."
ZSH_DIR="$HOME/.zsh"
mkdir -p "$ZSH_DIR"

declare -A PLUGINS=(
    [fzf-tab]="https://github.com/Aloxaf/fzf-tab.git"
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
    [zsh-completions]="https://github.com/zsh-users/zsh-completions.git"
    [zsh-history-substring-search]="https://github.com/zsh-users/zsh-history-substring-search.git"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

for plugin in "${!PLUGINS[@]}"; do
    if [ -d "$ZSH_DIR/$plugin" ]; then
        info "$plugin already cloned"
    else
        warn "Cloning $plugin..."
        git clone --depth 1 "${PLUGINS[$plugin]}" "$ZSH_DIR/$plugin"
        info "$plugin cloned"
    fi
done

# --------------------------------------------------
# 5. z.sh
# --------------------------------------------------
step "Setting up z.sh..."
if [ -f "$ZSH_DIR/z.sh" ]; then
    info "z.sh already present"
else
    cp "$DOTFILES/zsh/z.sh" "$ZSH_DIR/z.sh"
    info "z.sh copied to ~/.zsh/"
fi

# --------------------------------------------------
# 6. Config files (symlink with backup)
# --------------------------------------------------
step "Linking config files..."

symlink_config() {
    local src="$1"
    local dst="$2"
    local name="$3"

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        info "$name already linked"
        return
    fi

    # Backup existing file (not symlink)
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up existing $name to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    elif [ -L "$dst" ]; then
        rm "$dst"
    fi

    ln -s "$src" "$dst"
    info "$name → $dst"
}

symlink_config "$DOTFILES/.zshrc" "$HOME/.zshrc" ".zshrc"
symlink_config "$DOTFILES/starship.toml" "$HOME/.config/starship.toml" "starship.toml"
symlink_config "$DOTFILES/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "ghostty/config"

# --------------------------------------------------
# 7. Berkeley Mono Variable font
# --------------------------------------------------
step "Checking Berkeley Mono Variable font..."
if [ -f "$HOME/Library/Fonts/Berkeley-Mono-Variable.ttf" ]; then
    info "Berkeley Mono Variable already installed"
else
    warn "Berkeley Mono Variable font not found"
    warn "This is a paid font — buy it at https://berkeleygraphics.com/typefaces/berkeley-mono/"
    warn "Place the .ttf in ~/Library/Fonts/ manually"
    warn "Ghostty will fall back to a default font until then"
fi

# --------------------------------------------------
# Done
# --------------------------------------------------
echo -e "\n${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           Setup complete!            ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}\n"

info "Open a new terminal window to see your setup"
info "Or run: exec zsh"
