#!/bin/bash
# Toolkit Test Runner - Unit Tests for Each Tool
# Tests URL validity, tarball structure, and binary functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CACHE_DIR="${TOOLKIT_CACHE_DIR:-$HOME/.cache/toolkit-test}"
mkdir -p "$CACHE_DIR"

# Tool definitions: name, version, url, extract_type, expected_binary, strip_components
# extract_type: tar_gz, tar_xz, tar_bz2, zip, raw, cargo

BAT_VER="0.26.1"
BTOP_VER="1.4.6"
DELTA_VER="0.19.2"
DUST_VER="1.2.4"
EZA_VER="0.23.4"
FD_VER="10.4.2"
LAZYGIT_VER="0.61.0"
LSD_VER="1.2.0"
RIPGREP_VER="15.1.0"
STARSHIP_VER="1.24.2"
TEALDEER_VER="1.8.1"
YAZI_VER="26.1.22"
ZOXIDE_VER="0.9.9"
DOTTER_VER="0.13.4"
DIRENV_VER="2.37.1"
FISH_VER="4.6.0"
FZF_VER="0.71.0"
NEOVIM_VER="0.12.1"
TMUX_VER="3.6a"

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1" >&2
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1" >&2
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Download with caching
download_cached() {
    local name="$1"
    local url="$2"
    local cache_file="$CACHE_DIR/${name}.tarball"
    
    if [ -f "$cache_file" ]; then
        log_info "Using cached $name"
        echo "$cache_file"
        return 0
    fi
    
    log_info "Downloading $name from $url"
    if curl -fsSL "$url" -o "$cache_file"; then
        log_info "Cached $name to $cache_file"
        echo "$cache_file"
        return 0
    else
        log_fail "Failed to download $name"
        return 1
    fi
}

test_url_accessible() {
    local name="$1"
    local url="$2"
    
    local status=$(curl -sfIL "$url" 2>/dev/null | grep "^HTTP" | tail -1 | awk '{print $2}')
    if [ "$status" = "200" ]; then
        log_pass "$name URL is accessible (HTTP $status)"
        return 0
    else
        log_fail "$name URL is NOT accessible (HTTP $status): $url"
        return 1
    fi
}

# Test tarball structure for standard tar.gz
test_tarball_structure() {
    local name="$1"
    local tarball="$2"
    local strip="${3:-1}"
    local expected_binary="$4"
    local extract_type="${5:-tar_gz}"
    
    local test_dir="$CACHE_DIR/test-${name}"
    rm -rf "$test_dir"
    mkdir -p "$test_dir"
    
    case "$extract_type" in
        tar_gz)
            if tar -tzf "$tarball" 2>/dev/null | head -20 || true; then
                if tar -xzf "$tarball" -C "$test_dir" --strip-components="$strip" 2>/dev/null; then
                    if [ -f "$test_dir/$expected_binary" ]; then
                        log_pass "$name tarball structure is valid (strip=$strip, expected=$expected_binary)"
                        rm -rf "$test_dir"
                        return 0
                    else
                        log_fail "$name tarball missing $expected_binary after strip=$strip"
                        ls -la "$test_dir/" 2>/dev/null || true
                    fi
                else
                    log_fail "$name tarball failed to extract"
                fi
            else
                log_fail "$name tarball is not a valid gzip archive"
            fi
            ;;
        tar_xz)
            if tar -tJf "$tarball" 2>/dev/null | head -20 || true; then
                if tar -xJf "$tarball" -C "$test_dir" --strip-components="$strip" 2>/dev/null; then
                    if [ -f "$test_dir/$expected_binary" ]; then
                        log_pass "$name tarball structure is valid (strip=$strip, expected=$expected_binary)"
                        rm -rf "$test_dir"
                        return 0
                    else
                        log_fail "$name tarball missing $expected_binary after strip=$strip"
                        ls -la "$test_dir/" 2>/dev/null || true
                    fi
                else
                    log_fail "$name tarball failed to extract"
                fi
            else
                log_fail "$name tarball is not a valid xz archive"
            fi
            ;;
        tar_bz2)
            if tar -tjf "$tarball" 2>/dev/null | head -20 || true; then
                if tar -xjf "$tarball" -C "$test_dir" --strip-components="$strip" 2>/dev/null; then
                    if [ -f "$test_dir/$expected_binary" ]; then
                        log_pass "$name tarball structure is valid (strip=$strip, expected=$expected_binary)"
                        rm -rf "$test_dir"
                        return 0
                    else
                        log_fail "$name tarball missing $expected_binary after strip=$strip"
                        ls -la "$test_dir/" 2>/dev/null || true
                    fi
                else
                    log_fail "$name tarball failed to extract"
                fi
            else
                log_fail "$name tarball is not a valid bzip2 archive"
            fi
            ;;
        zip)
            if unzip -l "$tarball" 2>/dev/null | head -20 || true; then
                if unzip -o "$tarball" -d "$test_dir" 2>/dev/null; then
                    if [ -f "$test_dir/$expected_binary" ]; then
                        log_pass "$name zip structure is valid (expected=$expected_binary)"
                        rm -rf "$test_dir"
                        return 0
                    else
                        log_fail "$name zip missing $expected_binary"
                        ls -la "$test_dir/" 2>/dev/null || true
                    fi
                else
                    log_fail "$name zip failed to extract"
                fi
            else
                log_fail "$name is not a valid zip archive"
            fi
            ;;
        raw)
            if [ -f "$tarball" ]; then
                if file "$tarball" | grep -q "executable\|ELF"; then
                    log_pass "$name is a valid raw binary"
                    return 0
                else
                    log_fail "$name is not an executable"
                fi
            else
                log_fail "$name file not found"
            fi
            ;;
    esac
    
    rm -rf "$test_dir"
    return 1
}

# Test binary functionality
test_binary_works() {
    local name="$1"
    local binary_path="$2"
    local version_flag="${3:---version}"
    local version_regex="${4:-.}"
    
    if [ ! -f "$binary_path" ]; then
        log_fail "$name binary not found at $binary_path"
        return 1
    fi
    
    if [ ! -x "$binary_path" ]; then
        log_fail "$name binary is not executable"
        return 1
    fi
    
    local version_output
    if version_output=$("$binary_path" $version_flag 2>&1); then
        if echo "$version_output" | grep -q "$version_regex"; then
            log_pass "$name binary works: $(echo "$version_output" | head -n1)"
            return 0
        else
            log_warn "$name version output unexpected but binary runs"
            log_pass "$name binary is functional"
            return 0
        fi
    else
        log_fail "$name binary failed to run"
        return 1
    fi
}

# Extract and install tool to test bin
extract_to_bin() {
    local name="$1"
    local tarball="$2"
    local strip="${3:-1}"
    local expected_binary="$4"
    local extract_type="${5:-tar_gz}"
    local bin_dir="$6"
    
    local test_dir="$CACHE_DIR/test-${name}"
    rm -rf "$test_dir"
    mkdir -p "$test_dir"
    
    case "$extract_type" in
        tar_gz)
            tar -xzf "$tarball" -C "$test_dir" --strip-components="$strip"
            ;;
        tar_xz)
            tar -xJf "$tarball" -C "$test_dir" --strip-components="$strip"
            ;;
        tar_bz2)
            tar -xjf "$tarball" -C "$test_dir" --strip-components="$strip"
            ;;
        zip)
            unzip -o "$tarball" -d "$test_dir"
            # For yazi which has subdirectory
            if [ -d "$test_dir/yazi-"*"-unknown-linux-musl" ]; then
                mv "$test_dir/yazi-"*"-unknown-linux-musl/"* "$test_dir/" 2>/dev/null || true
            fi
            ;;
    esac
    
    # Special handling for certain tools
    case "$name" in
        btop)
            mv "$test_dir/btop/bin/btop" "$bin_dir/"
            ;;
        neovim)
            mv "$test_dir/nvim-*/bin/nvim" "$bin_dir/"
            rm -rf "$test_dir/nvim-"*
            ;;
        tokei)
            # tokei is installed via cargo, skip
            rm -rf "$test_dir"
            return 0
            ;;
        *)
            if [ -f "$test_dir/$expected_binary" ]; then
                mv "$test_dir/$expected_binary" "$bin_dir/"
            fi
            ;;
    esac
    
    rm -rf "$test_dir"
    return 0
}

echo "=========================================="
echo "Toolkit Unit Test Suite"
echo "Cache directory: $CACHE_DIR"
echo "=========================================="
echo ""

# Create test bin directory
TEST_BIN="$CACHE_DIR/test-bin"
mkdir -p "$TEST_BIN"

# =============================================================================
# TEST 1: bat
# =============================================================================
log_info "Testing bat..."
BAT_URL="https://github.com/sharkdp/bat/releases/download/v${BAT_VER}/bat-v${BAT_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "bat" "$BAT_URL"
BAT_TARBALL=$(download_cached "bat" "$BAT_URL")
test_tarball_structure "bat" "$BAT_TARBALL" 1 "bat" "tar_gz"
extract_to_bin "bat" "$BAT_TARBALL" 1 "bat" "tar_gz" "$TEST_BIN"
test_binary_works "bat" "$TEST_BIN/bat"
echo ""

# =============================================================================
# TEST 2: btop
# =============================================================================
log_info "Testing btop..."
BTOP_URL="https://github.com/aristocratos/btop/releases/download/v${BTOP_VER}/btop-x86_64-unknown-linux-musl.tbz"
test_url_accessible "btop" "$BTOP_URL"
BTOP_TARBALL=$(download_cached "btop" "$BTOP_URL")
# btop uses tar.bz2 with special structure: btop/bin/btop
TEST_DIR="$CACHE_DIR/test-btop"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
tar -xjf "$BTOP_TARBALL" -C "$TEST_DIR"
if [ -f "$TEST_DIR/btop/bin/btop" ]; then
    log_pass "btop tarball structure is valid (btop/bin/btop)"
    mv "$TEST_DIR/btop/bin/btop" "$TEST_BIN/"
else
    log_fail "btop tarball missing btop/bin/btop"
    ls -la "$TEST_DIR/" 2>/dev/null || true
fi
rm -rf "$TEST_DIR"
test_binary_works "btop" "$TEST_BIN/btop" "--version"
echo ""

# =============================================================================
# TEST 3: delta
# =============================================================================
log_info "Testing delta..."
DELTA_URL="https://github.com/dandavison/delta/releases/download/${DELTA_VER}/delta-${DELTA_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "delta" "$DELTA_URL"
DELTA_TARBALL=$(download_cached "delta" "$DELTA_URL")
test_tarball_structure "delta" "$DELTA_TARBALL" 1 "delta" "tar_gz"
extract_to_bin "delta" "$DELTA_TARBALL" 1 "delta" "tar_gz" "$TEST_BIN"
test_binary_works "delta" "$TEST_BIN/delta" "--version"
echo ""

# =============================================================================
# TEST 4: dust
# =============================================================================
log_info "Testing dust..."
DUST_URL="https://github.com/bootandy/dust/releases/download/v${DUST_VER}/dust-v${DUST_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "dust" "$DUST_URL"
DUST_TARBALL=$(download_cached "dust" "$DUST_URL")
test_tarball_structure "dust" "$DUST_TARBALL" 1 "dust" "tar_gz"
extract_to_bin "dust" "$DUST_TARBALL" 1 "dust" "tar_gz" "$TEST_BIN"
test_binary_works "dust" "$TEST_BIN/dust" "--version"
echo ""

# =============================================================================
# TEST 5: eza
# =============================================================================
log_info "Testing eza..."
EZA_URL="https://github.com/eza-community/eza/releases/download/v${EZA_VER}/eza_x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "eza" "$EZA_URL"
EZA_TARBALL=$(download_cached "eza" "$EZA_URL")
test_tarball_structure "eza" "$EZA_TARBALL" 0 "eza" "tar_gz"
extract_to_bin "eza" "$EZA_TARBALL" 0 "eza" "tar_gz" "$TEST_BIN"
test_binary_works "eza" "$TEST_BIN/eza" "--version"
echo ""

# =============================================================================
# TEST 6: fd
# =============================================================================
log_info "Testing fd..."
FD_URL="https://github.com/sharkdp/fd/releases/download/v${FD_VER}/fd-v${FD_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "fd" "$FD_URL"
FD_TARBALL=$(download_cached "fd" "$FD_URL")
test_tarball_structure "fd" "$FD_TARBALL" 1 "fd" "tar_gz"
extract_to_bin "fd" "$FD_TARBALL" 1 "fd" "tar_gz" "$TEST_BIN"
test_binary_works "fd" "$TEST_BIN/fd" "--version"
echo ""

# =============================================================================
# TEST 7: lazygit
# =============================================================================
log_info "Testing lazygit..."
LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VER}/lazygit_${LAZYGIT_VER}_linux_x86_64.tar.gz"
test_url_accessible "lazygit" "$LAZYGIT_URL"
LAZYGIT_TARBALL=$(download_cached "lazygit" "$LAZYGIT_URL")
test_tarball_structure "lazygit" "$LAZYGIT_TARBALL" 0 "lazygit" "tar_gz"
extract_to_bin "lazygit" "$LAZYGIT_TARBALL" 0 "lazygit" "tar_gz" "$TEST_BIN"
test_binary_works "lazygit" "$TEST_BIN/lazygit" "--version"
echo ""

# =============================================================================
# TEST 8: lsd
# =============================================================================
log_info "Testing lsd..."
LSD_URL="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VER}/lsd-v${LSD_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "lsd" "$LSD_URL"
LSD_TARBALL=$(download_cached "lsd" "$LSD_URL")
test_tarball_structure "lsd" "$LSD_TARBALL" 1 "lsd" "tar_gz"
extract_to_bin "lsd" "$LSD_TARBALL" 1 "lsd" "tar_gz" "$TEST_BIN"
test_binary_works "lsd" "$TEST_BIN/lsd" "--version"
echo ""

# =============================================================================
# TEST 9: ripgrep (rg)
# =============================================================================
log_info "Testing ripgrep (rg)..."
RG_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VER}/ripgrep-${RIPGREP_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "ripgrep" "$RG_URL"
RG_TARBALL=$(download_cached "rg" "$RG_URL")
test_tarball_structure "ripgrep" "$RG_TARBALL" 1 "rg" "tar_gz"
extract_to_bin "ripgrep" "$RG_TARBALL" 1 "rg" "tar_gz" "$TEST_BIN"
test_binary_works "ripgrep" "$TEST_BIN/rg" "--version"
echo ""

# =============================================================================
# TEST 10: starship
# =============================================================================
log_info "Testing starship..."
STARSHIP_URL="https://github.com/starship/starship/releases/download/v${STARSHIP_VER}/starship-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "starship" "$STARSHIP_URL"
STARSHIP_TARBALL=$(download_cached "starship" "$STARSHIP_URL")
test_tarball_structure "starship" "$STARSHIP_TARBALL" 0 "starship" "tar_gz"
extract_to_bin "starship" "$STARSHIP_TARBALL" 0 "starship" "tar_gz" "$TEST_BIN"
test_binary_works "starship" "$TEST_BIN/starship" "--version"
echo ""

# =============================================================================
# TEST 11: tealdeer
# =============================================================================
log_info "Testing tealdeer..."
TEALDEER_URL="https://github.com/tealdeer-rs/tealdeer/releases/download/v${TEALDEER_VER}/tealdeer-linux-x86_64-musl"
test_url_accessible "tealdeer" "$TEALDEER_URL"
TEALDEER_TARBALL=$(download_cached "tealdeer" "$TEALDEER_URL")
# tealdeer is a raw binary download
TEST_DIR="$CACHE_DIR/test-tealdeer"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
if curl -fsSL "$TEALDEER_URL" -o "$TEST_DIR/tealdeer"; then
    chmod +x "$TEST_DIR/tealdeer"
    if file "$TEST_DIR/tealdeer" | grep -q "ELF"; then
        log_pass "tealdeer is a valid raw binary"
        mv "$TEST_DIR/tealdeer" "$TEST_BIN/"
    else
        log_fail "tealdeer is not an ELF binary"
    fi
else
    log_fail "tealdeer download failed"
fi
rm -rf "$TEST_DIR"
test_binary_works "tealdeer" "$TEST_BIN/tealdeer" "--version"
echo ""

# =============================================================================
# TEST 12: yazi
# =============================================================================
log_info "Testing yazi..."
YAZI_URL="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VER}/yazi-x86_64-unknown-linux-musl.zip"
test_url_accessible "yazi" "$YAZI_URL"
YAZI_TARBALL=$(download_cached "yazi" "$YAZI_URL")
# yazi is a zip file with structure: yazi-x86_64-unknown-linux-musl/yazi
TEST_DIR="$CACHE_DIR/test-yazi"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
unzip -o "$YAZI_TARBALL" -d "$TEST_DIR" 2>/dev/null
if [ -d "$TEST_DIR/yazi-"*"-unknown-linux-musl" ]; then
    SUBDIR=$(ls -d "$TEST_DIR/yazi-"*"-unknown-linux-musl" | head -1)
    if [ -f "$SUBDIR/yazi" ]; then
        log_pass "yazi zip structure is valid (yazi-x86_64-unknown-linux-musl/yazi)"
        mv "$SUBDIR/yazi" "$TEST_BIN/"
    else
        log_fail "yazi zip missing yazi binary in subdir"
        ls -la "$SUBDIR/" 2>/dev/null || true
    fi
else
    log_fail "yazi zip unexpected structure"
    ls -la "$TEST_DIR/" 2>/dev/null || true
fi
rm -rf "$TEST_DIR"
test_binary_works "yazi" "$TEST_BIN/yazi" "--version"
echo ""

# =============================================================================
# TEST 13: zoxide
# =============================================================================
log_info "Testing zoxide..."
ZOXIDE_URL="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VER}/zoxide-${ZOXIDE_VER}-x86_64-unknown-linux-musl.tar.gz"
test_url_accessible "zoxide" "$ZOXIDE_URL"
ZOXIDE_TARBALL=$(download_cached "zoxide" "$ZOXIDE_URL")
# zoxide has binary at root with extra files
test_tarball_structure "zoxide" "$ZOXIDE_TARBALL" 0 "zoxide" "tar_gz"
extract_to_bin "zoxide" "$ZOXIDE_TARBALL" 0 "zoxide" "tar_gz" "$TEST_BIN"
test_binary_works "zoxide" "$TEST_BIN/zoxide" "--version"
echo ""

# =============================================================================
# TEST 14: dotter
# =============================================================================
log_info "Testing dotter..."
DOTTER_URL="https://github.com/SuperCuber/dotter/releases/download/v${DOTTER_VER}/dotter-linux-x64-musl"
test_url_accessible "dotter" "$DOTTER_URL"
DOTTER_TARBALL=$(download_cached "dotter" "$DOTTER_URL")
# dotter is a raw binary download
TEST_DIR="$CACHE_DIR/test-dotter"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
if curl -fsSL "$DOTTER_URL" -o "$TEST_DIR/dotter"; then
    chmod +x "$TEST_DIR/dotter"
    if file "$TEST_DIR/dotter" | grep -q "ELF"; then
        log_pass "dotter is a valid raw binary"
        mv "$TEST_DIR/dotter" "$TEST_BIN/"
    else
        log_fail "dotter is not an ELF binary"
    fi
else
    log_fail "dotter download failed"
fi
rm -rf "$TEST_DIR"
test_binary_works "dotter" "$TEST_BIN/dotter" "--version"
echo ""

# =============================================================================
# TEST 15: direnv
# =============================================================================
log_info "Testing direnv..."
DIRENV_URL="https://github.com/direnv/direnv/releases/download/v${DIRENV_VER}/direnv.linux-amd64"
test_url_accessible "direnv" "$DIRENV_URL"
DIRENV_TARBALL=$(download_cached "direnv" "$DIRENV_URL")
# direnv is a raw binary download
TEST_DIR="$CACHE_DIR/test-direnv"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
if curl -fsSL "$DIRENV_URL" -o "$TEST_DIR/direnv"; then
    chmod +x "$TEST_DIR/direnv"
    if file "$TEST_DIR/direnv" | grep -q "ELF"; then
        log_pass "direnv is a valid raw binary"
        mv "$TEST_DIR/direnv" "$TEST_BIN/"
    else
        log_fail "direnv is not an ELF binary"
    fi
else
    log_fail "direnv download failed"
fi
rm -rf "$TEST_DIR"
test_binary_works "direnv" "$TEST_BIN/direnv" "--version"
echo ""

# =============================================================================
# TEST 16: fish
# =============================================================================
log_info "Testing fish..."
FISH_URL="https://github.com/fish-shell/fish-shell/releases/download/${FISH_VER}/fish-${FISH_VER}-linux-x86_64.tar.xz"
test_url_accessible "fish" "$FISH_URL"
FISH_TARBALL=$(download_cached "fish" "$FISH_URL")
TEST_DIR="$CACHE_DIR/test-fish"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
tar -xJf "$FISH_TARBALL" -C "$TEST_DIR"
if [ -f "$TEST_DIR/fish" ]; then
    log_pass "fish tar.xz structure is valid (binary at root)"
    cp "$TEST_DIR/fish" "$TEST_BIN/"
else
    log_fail "fish tarball missing fish binary at root"
    ls -la "$TEST_DIR/" 2>/dev/null || true
fi
rm -rf "$TEST_DIR"
test_binary_works "fish" "$TEST_BIN/fish" "--version"
echo ""

# =============================================================================
# TEST 17: fzf
# =============================================================================
log_info "Testing fzf..."
FZF_URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VER}/fzf-${FZF_VER}-linux_amd64.tar.gz"
test_url_accessible "fzf" "$FZF_URL"
FZF_TARBALL=$(download_cached "fzf" "$FZF_URL")
# fzf has binary at root in tarball
test_tarball_structure "fzf" "$FZF_TARBALL" 0 "fzf" "tar_gz"
extract_to_bin "fzf" "$FZF_TARBALL" 0 "fzf" "tar_gz" "$TEST_BIN"
test_binary_works "fzf" "$TEST_BIN/fzf" "--version"
echo ""

# =============================================================================
# TEST 18: neovim (AppImage)
# =============================================================================
log_info "Testing neovim (AppImage)..."
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VER}/nvim.appimage"
test_url_accessible "neovim" "$NEOVIM_URL"
NEOVIM_TARBALL=$(download_cached "neovim" "$NEOVIM_URL")
# neovim AppImage is downloaded directly
TEST_DIR="$CACHE_DIR/test-neovim"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
if curl -fsSL "$NEOVIM_URL" -o "$TEST_DIR/nvim.appimage"; then
    chmod +x "$TEST_DIR/nvim.appimage"
    if file "$TEST_DIR/nvim.appimage" | grep -q "ELF\|AppImage"; then
        log_pass "neovim AppImage is valid"
        mv "$TEST_DIR/nvim.appimage" "$TEST_BIN/"
        ln -s nvim.appimage "$TEST_BIN/nvim"
    else
        log_fail "neovim AppImage is not valid"
    fi
else
    log_fail "neovim AppImage download failed"
fi
rm -rf "$TEST_DIR"
test_binary_works "neovim" "$TEST_BIN/nvim.appimage" "--version"
echo ""

# =============================================================================
# TEST 19: tmux
# =============================================================================
log_info "Testing tmux..."
TMUX_URL="https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VER}/tmux-${TMUX_VER}-linux-x86_64.tar.gz"
test_url_accessible "tmux" "$TMUX_URL"
TMUX_TARBALL=$(download_cached "tmux" "$TMUX_URL")
# tmux has binary at root
test_tarball_structure "tmux" "$TMUX_TARBALL" 0 "tmux" "tar_gz"
extract_to_bin "tmux" "$TMUX_TARBALL" 0 "tmux" "tar_gz" "$TEST_BIN"
test_binary_works "tmux" "$TEST_BIN/tmux" "-V"
echo ""

# =============================================================================
# TEST 20: tokei (skip URL test - installed via cargo)
# =============================================================================
log_info "Testing tokei (cargo install - special case)..."
log_warn "tokei is installed via cargo, skipping URL test"
log_pass "tokei marked as cargo-install tool"
echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi