# Git Hooks

## Pre-commit Hook

This optional pre-commit hook checks the staged publication contents without printing matched values, then runs the MoonBit checker through the portable toolchain wrapper.

### Usage Instructions

To use this pre-commit hook:

1. Make the hook executable if it isn't already:
   ```bash
   chmod +x .githooks/pre-commit
   ```

2. Configure Git to use the hooks in the .githooks directory:
   ```bash
   git config core.hooksPath .githooks
   ```

3. The hook will automatically run when you execute `git commit`
