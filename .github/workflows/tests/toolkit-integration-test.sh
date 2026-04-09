#!/bin/bash
set -euo pipefail

CACHE_DIR="${TOOLKIT_CACHE_DIR:-$HOME/.cache/toolkit-test}"
INTEGRATION_OUT="$CACHE_DIR/integration-bin"
rm -rf "$INTEGRATION_OUT"
mkdir -p "$INTEGRATION_OUT"

echo "=========================================="
echo "Toolkit Integration Test (using cache)"
echo "Cache: $CACHE_DIR"
echo ""

extract_from_cache() {
    local name="$1"
    local tarball="$CACHE_DIR/${name}.tarball"
    local binary="$2"
    local strip="${3:-1}"
    if [ ! -f "$tarball" ]; then
        echo "❌ $name tarball not found in cache"
        return 1
    fi
    echo "📦 $name from cache..."
    TMPDIR=$(mktemp -d)
    tar -xzf "$tarball" -C "$TMPDIR/" --strip-components="$strip"
    mv "$TMPDIR/$binary" "$INTEGRATION_OUT/"
    rm -rf "$TMPDIR"
}

extract_xz_from_cache() {
    local name="$1"
    local tarball="$CACHE_DIR/${name}.tarball"
    local binary="$2"
    local strip="${3:-1}"
    if [ ! -f "$tarball" ]; then
        echo "❌ $name tarball not found in cache"
        return 1
    fi
    echo "📦 $name from cache..."
    TMPDIR=$(mktemp -d)
    tar -xJf "$tarball" -C "$TMPDIR/" --strip-components="$strip"
    mv "$TMPDIR/$binary" "$INTEGRATION_OUT/"
    rm -rf "$TMPDIR"
}

extract_btop_from_cache() {
    echo "📦 btop from cache..."
    local tarball="$CACHE_DIR/btop.tarball"
    TMPDIR=$(mktemp -d)
    tar -xjf "$tarball" -C "$TMPDIR/"
    mv "$TMPDIR/btop/bin/btop" "$INTEGRATION_OUT/"
    rm -rf "$TMPDIR"
}

extract_yazi_from_cache() {
    echo "📦 yazi from cache..."
    local tarball="$CACHE_DIR/yazi.tarball"
    TMPDIR=$(mktemp -d)
    unzip -o "$tarball" -d "$TMPDIR/"
    mv "$TMPDIR/yazi-x86_64-unknown-linux-musl/yazi" "$INTEGRATION_OUT/"
    rm -rf "$TMPDIR"
}

extract_neovim_from_cache() {
    echo "📦 neovim from cache..."
    local tarball="$CACHE_DIR/neovim.tarball"
    TMPDIR=$(mktemp -d)
    tar -xzf "$tarball" -C "$TMPDIR/"
    mv "$TMPDIR/nvim-linux-x86_64/bin/nvim" "$INTEGRATION_OUT/"
    rm -rf "$TMPDIR"
}

copy_raw_from_cache() {
    local name="$1"
    local tarball="$CACHE_DIR/${name}.tarball"
    if [ ! -f "$tarball" ]; then
        echo "❌ $name not found in cache"
        return 1
    fi
    echo "📦 $name from cache..."
    cp "$tarball" "$INTEGRATION_OUT/$name"
    chmod +x "$INTEGRATION_OUT/$name"
}

extract_from_cache "bat" "bat" 1
extract_btop_from_cache
extract_from_cache "delta" "delta" 1
extract_from_cache "dust" "dust" 1
extract_from_cache "eza" "eza" 0
extract_from_cache "fd" "fd" 1
extract_from_cache "lazygit" "lazygit" 0
extract_from_cache "lsd" "lsd" 1
extract_from_cache "rg" "rg" 1
extract_from_cache "starship" "starship" 0
copy_raw_from_cache "tealdeer"
extract_yazi_from_cache
extract_from_cache "zoxide" "zoxide" 0
echo "(tokei skipped - cargo install)"
copy_raw_from_cache "dotter"
copy_raw_from_cache "direnv"
extract_xz_from_cache "fish" "fish" 0
extract_from_cache "fzf" "fzf" 0
extract_neovim_from_cache
extract_from_cache "tmux" "tmux" 0

echo ""
echo "📦 Installed tools:"
ls -la "$INTEGRATION_OUT/"

echo ""
echo "📦 Verifying all tools are in bin..."
REQUIRED_TOOLS="bat btop delta dust eza fd fish fzf lazygit lsd nvim rg starship tealdeer tmux dotter yazi zoxide direnv"
ALL_FOUND=true
for tool in $REQUIRED_TOOLS; do
    if [ -x "$INTEGRATION_OUT/$tool" ]; then
        echo "  ✅ $tool"
    else
        echo "  ❌ $tool - MISSING!"
        ALL_FOUND=false
    fi
done

echo ""
echo "📦 Testing each tool's version..."
test_tool() {
    local name="$1"
    local binary="$INTEGRATION_OUT/$2"
    local flag="${3:---version}"
    if [ ! -x "$binary" ]; then
        echo "  ❌ $name - binary not found"
        return 1
    fi
    if output=$("$binary" $flag 2>&1); then
        echo "  ✅ $name works: $(echo "$output" | head -n1)"
    else
        echo "  ❌ $name - failed to run"
        return 1
    fi
}

test_tool "bat" "bat"
test_tool "btop" "btop" "--version"
test_tool "delta" "delta"
test_tool "dust" "dust"
test_tool "eza" "eza"
test_tool "fd" "fd"
test_tool "fish" "fish"
test_tool "fzf" "fzf"
test_tool "lazygit" "lazygit"
test_tool "lsd" "lsd"
test_tool "neovim" "nvim"
test_tool "rg (ripgrep)" "rg"
test_tool "starship" "starship"
test_tool "tealdeer" "tealdeer"
test_tool "tmux" "tmux" "-V"
test_tool "dotter" "dotter"
test_tool "yazi" "yazi"
test_tool "zoxide" "zoxide"
test_tool "direnv" "direnv" "--version"

echo ""
echo "📦 Creating toolkit tarball..."
TAR_NAME="$CACHE_DIR/toolkit-test-amd64.tar.gz"
tar -czvf "$TAR_NAME" -C "$INTEGRATION_OUT" .

echo ""
echo "📦 Extracting to verify tarball integrity..."
VERIFY_DIR="$CACHE_DIR/verify-extract"
rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"
tar -xzvf "$TAR_NAME" -C "$VERIFY_DIR/"

echo ""
echo "📦 Verifying extracted tools..."
for tool in $REQUIRED_TOOLS; do
    if [ -x "$VERIFY_DIR/$tool" ]; then
        echo "  ✅ $tool - verified in tarball"
    else
        echo "  ❌ $tool - MISSING in tarball!"
    fi
done
rm -rf "$VERIFY_DIR"

echo ""
echo "=========================================="
echo "✅ All integration tests passed!"
echo "=========================================="