# DOTFILES / CLI-TOOLKITS

**Generated:** 2026-04-10
**Commit:** e25a584
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
| tealdeer, dotter, direnv | `download_raw` | direct binary |
| tokei | cargo install | special |

## WORKFLOW MODIFICATION RULES

### URL Verification (CRITICAL)
Before modifying `toolkit.yml` with a new or changed URL:
1. **Always verify URL is accessible** with `curl -sfI <url>` first
2. **Check the exact filename** in the release - GitHub release assets use specific naming patterns (e.g., `nvim-linux-x86_64.appimage`, NOT `nvim.appimage`)
3. **Document the correct URL** in your edit

Example workflow:
```bash
# Verify before editing
curl -sfI "https://github.com/neovim/neovim/releases/download/v0.12.1/nvim-linux-x86_64.appimage"
# If 200 OK, safe to proceed
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
- 20 tools: bat, btop, delta, dust, eza, fd, fish, fzf, lazygit, lsd, neovim, rg, starship, tealdeer, tmux, tokei, dotter, yazi, zoxide, direnv
- Binary names match tool names except: ripgrep→rg, neovim→nvim
