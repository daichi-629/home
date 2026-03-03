# Regenerate node2nix Nix expressions from package.json
#
# Workflow:
#   1. Edit package.json to add/remove packages
#   2. Run: make update
#   3. Commit all generated files (package-lock.json, default.nix, node-packages.nix, node-env.nix)
#
# Note: pnpm generates pnpm-lock.yaml, but node2nix requires package-lock.json (npm v2 format).
#       `npm` here refers to the real npm binary (Makefile does not inherit shell aliases),
#       so the pnpm alias in zsh does not apply.

.PHONY: update

update:
	# Generate package-lock.json using npm's dependency resolution algorithm
	npm install --package-lock-only --ignore-scripts --lockfile-version=2
	# Convert lock file to Nix expressions
	node2nix -i package.json -l package-lock.json
