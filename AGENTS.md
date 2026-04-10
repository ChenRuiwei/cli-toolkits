# DOTFILES / CLI-TOOLKITS

**Generated:** 2026-04-10
**Commit:** fb67192
**Branch:** main

## OVERVIEW
CLI toolkit installer with GitHub Actions build system. Downloads prebuilt binaries for 20 tools.

## STRUCTURE
```
./
├── toolkit.sh                    # Main install script
└── .github/workflows/
    ├── toolkit.yml              # Build workflow
    └── tests/
        ├── toolkit-unit-tests.sh      # 58 unit tests
        └── toolkit-integration-test.sh # Integration test
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add new tool | `.github/workflows/toolkit.yml` | Add `extract_single` call |
| Fix URL/tarball | `toolkit-unit-tests.sh` | Test extraction logic |
| Verify build | `.github/workflows/tests/` | Run both test scripts |

## CODE MAP
| Tool | Install Method | Binary Location |
|------|---------------|----------------|
| bat, delta, dust, fd, lsd, rg | `extract_single` strip=1 | tar/{binary} |
| eza, lazygit, starship, zoxide, fzf, tmux | `extract_single` strip=0 | tar/{binary} at root |
| fish | `extract_xz_single` strip=0 | tar.xz/{binary} |
| btop | special tar.bz2 | btop/bin/{binary} |
| neovim | AppImage | nvim.appimage + nvim symlink |
| yazi | unzip | zip/{binary} |
| tree-sitter-cli | unzip | zip/{binary} |
| tealdeer, dotter, direnv | `download_raw` | direct binary |
| tokei | cargo install | special |

## WORKFLOW RULES (MANDATORY)

### 1. Modify toolkit.yml Only After Tests Pass
Before ANY change to `toolkit.yml`:
1. Verify URL accessibility with `curl -sfI <url>`
2. Run unit tests: `TOOLKIT_CACHE_DIR="$HOME/.cache/toolkit-test" bash .github/workflows/tests/toolkit-unit-tests.sh`
3. Run integration tests: `TOOLKIT_CACHE_DIR="$HOME/.cache/toolkit-test" bash .github/workflows/tests/toolkit-integration-test.sh`
4. Only modify `toolkit.yml` AFTER both tests pass
5. Commit and push only after tests pass

### 2. Keep yml, Tests, and toolkit.sh in Sync (1:1 Correspondence)
Every tool in `toolkit.yml` MUST have a corresponding test in BOTH test scripts AND a version check in `toolkit.sh`.
When you modify a tool in `toolkit.yml`, you MUST update:
- `toolkit-unit-tests.sh` - URL test + structure test + binary test
- `toolkit-integration-test.sh` - extract logic + verification
- `toolkit.sh` - version check echo line

If they don't match 1:1, something is wrong.

### 3. Preserve Tarball Cache During Testing
- Do NOT clear `~/.cache/toolkit-test/` between test runs
- Do NOT re-download tarballs unnecessarily
- The cache is intentional - reuse it to speed up testing
- If you need a fresh start: only clear `test-bin/` and `integration-bin/`, not the tarballs

### URL Verification (CRITICAL)
Before modifying `toolkit.yml` with a new or changed URL:
1. **Always verify URL is accessible** with `curl -sfI <url>` first
2. **Check the exact filename** in the release - GitHub release assets use specific naming patterns (e.g., `nvim-linux-x86_64.appimage`, NOT `nvim.appimage`)
3. **Document the correct URL** in your edit

Example workflow:
```bash
# 1. Verify URL first
curl -sfI "https://github.com/neovim/neovim/releases/download/v0.12.1/nvim-linux-x86_64.appimage"

# 2. Run tests (cache is reused, no re-download)
TOOLKIT_CACHE_DIR="$HOME/.cache/toolkit-test" bash .github/workflows/tests/toolkit-unit-tests.sh
TOOLKIT_CACHE_DIR="$HOME/.cache/toolkit-test" bash .github/workflows/tests/toolkit-integration-test.sh

# 3. Only after tests pass, modify toolkit.yml
```

## CONVENTIONS
- Functions use temp dir for extraction, clean up after
- Only tool binary goes to bin/, no extra files
- tarball caching: `~/.cache/toolkit-test/`

## ANTI-PATTERNS
- `download_raw` for tar archives (use `extract_single`)
- Extracting without temp dir cleanup
- Adding garbage files to bin/ (README, LICENSE, etc.)

## COMMANDS
```bash
# Run tests (uses cached tarballs)
~/.cache/toolkit-test/toolkit-unit-tests.sh
~/.cache/toolkit-test/toolkit-integration-test.sh

# Fresh install (no cache)
./toolkit.sh
```

## NOTES
- 21 tools: bat, btop, delta, dust, eza, fd, fish, fzf, lazygit, lsd, neovim, rg, starship, tealdeer, tmux, tokei, dotter, yazi, zoxide, direnv, tree-sitter-cli
- Binary names match tool names except: ripgrep→rg, neovim→nvim
- neovim uses AppImage with symlink: nvim → nvim.appimage
- tealdeer provides tldr symlink: tldr → tealdeer
