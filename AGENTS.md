# AGENTS.md

## Project Overview
hnsw-rust is a from-scratch HNSW (Hierarchical Navigable Small World) approximate nearest-neighbor index in Rust. Solves fast k-NN search over dense vectors without external dependencies.

## Development Philosophy
- TDD first: write the test, then the implementation. Never skip.
- Tests live in-module (`#[cfg(test)]`) for units, `tests/` for integration.
- No function ships without a test.
- Explicit over clever — readable code beats smart code.
- If it isn't runnable via `make`, it isn't done.
- After every feature run finishes, push to git.

## Tech Stack
- Language: Rust (edition 2024), stable toolchain
- Package Manager / Build: Cargo (single crate, lib + demo binary)
- Dependencies: std-only by default — add a crate only if std can't do it cleanly
- Build/Task Runner: **Make** — root `Makefile` is the single entry point for setup, test, lint, and build.

## Key Commands

All commands run via `make <target>` from the project root. Calling `cargo` directly is for the Makefile's internal use only.

```bash
make setup                       # installs toolchain (rustup), checks cargo setup
make test                        # cargo test (all targets)
make style                       # cargo fmt --check + cargo clippy -- -D warnings
make build                       # cargo build --release
make clean                       # cargo clean + remove build artifacts
```

## Directory Structure

```
hnsw-rust/
├── src/
│   ├── lib.rs                   # crate root, public API re-exports
│   ├── hnsw.rs                  # Hnsw index: insert, search, params (M, ef_construction)
│   ├── graph.rs                 # layered graph storage, neighbor lists
│   ├── distance.rs              # distance fns (euclidean, cosine) + trait
│   └── main.rs                  # tiny demo binary (build index, query, print recall)
├── tests/
│   └── integration_test.rs      # end-to-end insert + search recall checks
├── benches/                     # criterion benches (add only when needed)
├── docs/
│   └── features.json            # canonical feature tracker — always kept up to date
├── Cargo.toml
├── Makefile                     # single entry point for setup/test/style/build/clean
├── .gitignore
├── README.md
└── AGENTS.md
```

## Conventions

### Makefile (required)
- Root-level `Makefile` is **mandatory**, thin wrapper over `cargo`.
- Required targets: `setup`, `test`, `style`, `build`, `clean`. Never remove.
- `make setup` is idempotent and safe to re-run.
- Every target has a `## short description` comment so `make help` works.

### Rust
- Formatter: `cargo fmt`, Linter: `cargo clippy -- -D warnings` (both via `make style`).
- Naming: snake_case for files/functions/variables, PascalCase for types/traits, SCREAMING_SNAKE_CASE for consts.
- Public API lives in `lib.rs` re-exports; keep `main.rs` to demo/bench plumbing only.
- No `unwrap()`/`expect()` in library code (tests + `main.rs` only) — return `Result` or `Option`.
- No new dependencies without asking — std-only is the default.
- Docs: `///` on all public items with a `# Example` where behavior isn't obvious.

### General
- Commits: conventional commits (feat:, fix:, chore:, docs:, test:, refactor:).
- **All setup/test/style/build steps run through the root `Makefile`.**
- **README badges**: HTML shield badges (via [shields.io](https://shields.io)) for build, version, license. Use raw HTML `<img>` tags, not Markdown images.

## Deployment Philosophy

No deployment — this is a library crate. "Release" means `cargo publish` (crates.io) when explicitly requested, plus tagged git releases. No Docker, no hosting.

## Multi-Agent Workflow

When `docs/features.json` contains 3+ independent features (different modules, no shared state), parallelize with subagents.

### Flow

1. **Plan**: Identify independent features. Same-file features are dependent, batch sequentially.
2. **Build**: Spawn up to 3 builder subagents at a time. When one completes, spawn the next.
3. **Review**: Spawn ponytail-reviewer on the combined diff for over-engineering.
4. **Verify**: Run `make test && make style`.

If fewer than 3 independent features, implement directly without subagents.

### Subagents

Subagents in `~/.config/opencode/agents/`.

| Agent | File | Purpose | Permissions |
|-------|------|---------|-------------|
| builder | `builder.md` | TDD one feature, tests then implementation | edit: allow, bash: allow |
| ponytail-reviewer | `ponytail-reviewer.md` | Bloat/over-engineering audit on combined diff | edit: deny, bash: allow |

## Agent Guidelines
- Always run `make style` before considering any code done.
- Always run `make test` after changes — fix failures before moving on.
- Always update `docs/features.json` after completing any task.
- Any new setup/test/style/build step goes in the Makefile, not prose.
- Never add a dependency without asking — justify why std is insufficient.
- If something feels out of scope, flag it rather than silently doing it.
- If >=3 independent features exist in docs/features.json, spawn builder subagents (max 3 concurrent).

`docs/features.json`

```json
{
  "project": "hnsw-rust",
  "last_updated": "YYYY-MM-DD",
  "summary": {
    "total": 0,
    "completed": 0,
    "in_progress": 0,
    "planned": 0,
    "tests_passing": 0,
    "tests_failing": 0,
    "tests_missing": 0
  },
  "features": [
    {
      "id": "F001",
      "name": "[Feature Name]",
      "description": "[What it does and why it exists]",
      "status": "planned",
      "priority": "high",
      "module": "src/[module].rs",
      "design_doc": "docs/[relevant-design-doc].md",
      "tests": {
        "status": "missing",
        "files": [],
        "notes": ""
      },
      "subtasks": [
        {
          "id": "F001-1",
          "name": "[Subtask name]",
          "status": "planned"
        }
      ],
      "notes": "",
      "added": "YYYY-MM-DD",
      "completed": null
    }
  ]
}
```

## Project-Specific Notes
- HNSW params: `M` (max neighbors), `ef_construction`, `ef_search`, `mL` level multiplier — keep in one `HnswConfig` struct.
- Level sampling uses exponential decay (`-ln(uniform) * mL`); RNG must be seedable for deterministic tests.
- Distance default: Euclidean (L2); cosine as second metric. Trait-gated so new metrics are one fn.
- Correctness bar: brute-force recall check in `tests/` — HNSW results must match exact k-NN within tolerance on small fixtures.
- Never touch: `Cargo.lock` by hand (cargo owns it), `target/` (gitignored).
