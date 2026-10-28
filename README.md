# homebrew-bushpilot

Homebrew tap for [Bushpilot](https://github.com/frank321/bushpilot) — a
hardware-aware local LLM cockpit for Apple Silicon.

## Install

```sh
brew install frank321/bushpilot/bushpilot
```

This adds the tap and installs the formula in one step. Or tap first, then install:

```sh
brew tap frank321/bushpilot
brew install bushpilot
```

## Use

```sh
bushpilot-server      # start the MLX model server + dashboard (leave running)
bushpilot             # attach a coding tool (Claude Code/OpenCode/Aider/Cline/Pi)
bushpilot-uninstall   # remove downloaded models and state
```

Everything Bushpilot downloads (its Python venv, model weights, logs) lives under
`~/.bushpilot/`. Removing that directory is a full reset; `bushpilot-uninstall`
does it for you.

## Upgrade

```sh
brew update && brew upgrade bushpilot
```

The formula auto-bumps: a scheduled GitHub Actions workflow in this repo runs
`brew livecheck`, and when the upstream project publishes a new `v*` release it
rewrites the formula's `url`/`sha256` and commits the bump here. No manual edits.

## How this tap works

- `Formula/bushpilot.rb` installs the upstream project's prebuilt `bushpilot.zip`
  release asset into `libexec` and exposes `bushpilot`, `bushpilot-server`, and
  `bushpilot-uninstall` as `bin` wrappers.
- `.github/workflows/update-formula.yml` — the scheduled `livecheck` auto-bump.
- `.github/workflows/lint.yml` — runs `brew audit` / `brew style` on formula changes.

Requires an Apple Silicon Mac. Intel Macs and Linux are not supported (the MLX
backend and the model catalog target arm64/Metal).
