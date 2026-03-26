# AGENTS.md — Adalin

Practical reference for AI coding agents working in this repository.

---

## Repository Layout

```
adalin/                  # Root — main library crate
├── src/                 # Library source files (adalin*.ads/adb)
├── config/              # Auto-generated alire config (do not edit)
├── obj/                 # Build artefacts (gitignored)
├── lib/                 # Built library output (gitignored)
├── share/               # Installed artefacts
├── tests/               # Standalone test crate (separate alr workspace)
│   └── src/             # Unit test sources (tests-*.ads/adb)
├── demo_slave/          # Standalone demo application crate
├── .continue/           # Continue AI agent config (agents, rules, prompts)
├── .vscode/             # VS Code tasks and launch configs
├── .devcontainer/       # Dev container definition (Ubuntu base image)
├── adalin.gpr           # Main GPRbuild project file
└── alire.toml           # Root crate manifest
```

---

## Build

Always use `alr`, never call `gprbuild` directly.

| Action | Command | Working Directory |
|---|---|---|
| Build library | `alr build` | `adalin/` |
| Run unit tests | `alr run` | `adalin/tests/` |
| Run demo slave | `alr run` | `adalin/demo_slave/` |

**Post-build:** `alr build` automatically runs `gnatprove` at level 0 on the library (see [`alire.toml`](alire.toml) `[[actions]]`).

---

## SPARK Proof

The library uses SPARK. `gnatprove` is a declared dependency (`gnatprove = "^15.1.0"`).

Run proof manually:
```powershell
# Whole library, level 0 (fast — flow analysis only)
alr exec -- gnatprove -P adalin.gpr --level=0 -j0

# Single package, higher level
alr exec -- gnatprove -P adalin.gpr --level=3 -j0 -u adalin-signals.adb
```

- Proof levels run from `0` (flow analysis only) to `4` (most thorough).
- `-j0` uses all available CPU cores.
- `gnatprove` is the binary name; `gprprove` does not exist in this toolchain.

### SPARK code rules
- Query functions (`Get_*`, `Is_*`) must be completed as **expression functions** in the `private` section of the spec so the prover can see through the private type.
- Helper functions used in postconditions (e.g. `Constrain`) must also be expression functions.
- Packages with a body and `SPARK_Mode => On` that declare derived tagged types must include `pragma Elaborate_Body` in the spec (SPARK rule E0003).

---

## Unit Tests

- Framework: **AUnit** (`aunit = "^25.0.0"`)
- Test sources: `tests/src/`
- Naming convention: `tests-<functionality>.adb/.ads`
- Entry point: `tests/src/adalin_tests.adb`
- Build profile for the `adalin` dependency is forced to `development` in `tests/alire.toml`
- Coverage tooling: `gnatcov` (`gnatcov = "^22.0.1"`) is declared but not yet wired to a task

---

## Dependencies

### `adalin/alire.toml` (library)
| Crate | Version |
|---|---|
| `gnatprove` | `^15.1.0` |

### `tests/alire.toml` (test crate — pins `adalin` to `..`)
| Crate | Version |
|---|---|
| `aunit` | `^25.0.0` |
| `gnatcov` | `^22.0.1` |
| `adalin` | `^0.1.0-dev` |

---

## Code Style

- Ada standard: **Ada 2022** (`-gnat2022` switch in both `.gpr` files)
- Symbolic tracebacks enabled (`-Es` binder switch)
- Style checks are active; violations are treated as errors. Key enforced rules:
  - No horizontal tabs (`-gnatyh`) — use spaces
  - Max line length 80 characters (`-gnatyM80`)
- Non-ASCII characters in source comments will cause encoding issues with some tools — use plain ASCII.

---

## Terminal / Shell

- **Windows:** use PowerShell for all terminal commands.
- **Linux / macOS:** use Bash.
- `&&` is not a valid statement separator in PowerShell; use `;` instead.
  ```powershell
  cd D:\ada\adalin; alr build
  ```

---

## VS Code Tasks

Defined in `.vscode/tasks.json`:

| Label | Action |
|---|---|
| `ada: Run unit tests` | `alr run` in `tests/` |
| `ada: Run demo slave` | `alr run` in `demo_slave/` |

---

## Dev Container

- Base image: `mcr.microsoft.com/devcontainers/base:ubuntu`
- VS Code extension auto-installed: `AdaCore.ada`
- No `postCreateCommand` — install the Alire toolchain manually after container creation.

---

## Continue AI Agent Config

Located in `.continue/` at the repo root.

| Path | Purpose |
|---|---|
| `.continue/agents/flyergpt.yaml` | Default chat/autocomplete agent (Claude Sonnet, Azure endpoint) |
| `.continue/agents/agentsmd-updater.yaml` | Agent for maintaining this file |
| `.continue/rules/unit-tests.md` | Unit test conventions injected into context |
| `.continue/rules/terminal-rules.md` | Shell/terminal rules injected into context |
| `.continue/prompts/new-prompt.md` | "Fix issues" slash-command prompt |

The `agentsmd-updater` agent should be invoked whenever build steps, dependencies, directory structure, code style rules, or workflows change.
