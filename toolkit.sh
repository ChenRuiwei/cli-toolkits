#!/bin/bash

REPO="ChenRuiwei/cli-toolkits"

ARCH=$(uname -m)
case $ARCH in
    x86_64|amd64)
        SUFFIX="amd64"
        ;;
    aarch64|arm64)
        SUFFIX="arm64"
        ;;
    *)
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

FILE="toolkit-${SUFFIX}.tar.gz"

VERSION=${1:-"latest"}
if [ "$VERSION" = "latest" ]; then
    URL="https://github.com/${REPO}/releases/latest/download/${FILE}"
else
    echo "🔙 Targeting specific version: $VERSION"
    URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILE}"
fi

DEST="${HOME}/.local/bin"

echo "=================================================="
echo "🚀 Architecture: $ARCH ($SUFFIX)"
echo "📦 Package:      $FILE"
echo "🎯 Version:      $VERSION"
echo "📂 Destination:  $DEST"
echo "=================================================="

mkdir -p "$DEST"

echo "⬇️ Downloading..."
TMPFILE=$(mktemp)
curl -L -f --progress-bar "$URL" -o "$TMPFILE"
tar -xz -C "$DEST" -f "$TMPFILE"
rm -f "$TMPFILE"

if [ $? -eq 0 ]; then
    echo "✅ Success! Tools installed."
    echo ""
    echo "Current versions:"
    echo "-----------------"
    echo "bat:      $("$DEST/bat" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "btop:     $("$DEST/btop" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "delta:    $("$DEST/delta" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "direnv:   $($DEST/direnv --version 2>/dev/null || echo "N/A")"
    echo "dust:     $("$DEST/dust" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "eza:      $("$DEST/eza" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "fd:       $("$DEST/fd" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "fish:     $("$DEST/fish" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "fzf:      $($DEST/fzf --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "lazygit:  $("$DEST/lazygit" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "lsd:      $("$DEST/lsd" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "neovim:   $($DEST/nvim --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "rg:       $("$DEST/rg" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "starship: $($DEST/starship --version 2>/dev/null || echo "N/A")"
    echo "tealdeer: $("$DEST/tealdeer" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "tmux:     $($DEST/tmux -V 2>/dev/null || echo "N/A")"
    echo "tokei:    $("$DEST/tokei" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "dotter:   $("$DEST/dotter" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "yazi:     $("$DEST/yazi" --version 2>/dev/null | head -n 1 || echo "N/A")"
    echo "zoxide:   $("$DEST/zoxide" --version 2>/dev/null | head -n 1 || echo "N/A")"
else
    echo "❌ Deployment failed."
    echo "   Please check if version '$VERSION' exists in Release page."
    exit 1
fi
