.PHONY: setup test style build clean help

setup: ## installs toolchain (rustup), checks cargo setup
	rustup toolchain install stable --profile minimal --component clippy rustfmt
	cargo --version

test: ## cargo test (all targets)
	cargo test --all-targets

style: ## cargo fmt --check + cargo clippy -- -D warnings
	cargo fmt --check
	cargo clippy --all-targets -- -D warnings

build: ## cargo build --release
	cargo build --release

clean: ## cargo clean + remove build artifacts
	cargo clean

help: ## show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "%-10s %s\n", $$1, $$2}'
