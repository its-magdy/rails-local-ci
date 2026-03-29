# Contributing

Thanks for your interest in contributing to rails-local-ci!

## Setup

```bash
git clone https://github.com/its-magdy/rails-local-ci.git
cd rails-local-ci
bundle install
```

## Running Tests

```bash
bundle exec ruby test/continuous_integration_test.rb
```

## Implementation Sync

This gem tracks Rails `main`. The core class (`lib/active_support/continuous_integration.rb`) is kept in sync with the upstream Rails implementation. If you're syncing a new upstream commit, update the sync note in `AGENTS.md`.

## Submitting Changes

1. Fork the repo and create a branch from `main`
2. Make your changes and add tests if applicable
3. Ensure tests pass
4. Open a pull request with a clear description of the change

## Reporting Bugs

Open an issue at https://github.com/its-magdy/rails-local-ci/issues.
