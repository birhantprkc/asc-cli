.PHONY: build test lint format clean dev run docs check-docs

build:
	swift build

test:
	swift test

lint:
	swift package diagnose-api-breaking-changes 2>/dev/null || true
	@echo "Lint complete"

format:
	swift format --in-place --recursive Sources Tests

clean:
	swift package clean
	rm -rf .build

dev: build
	.build/debug/asc --help

run:
	swift run asc $(ARGS)

# Regenerate docs/commands.md and docs/README.md (never edit those by hand)
docs: build
	python3 scripts/gen-docs.py .build/debug/asc

check-docs:
	python3 scripts/check-docs.py
