# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Purpose

A Ruby gem that backports Rails 8.1's `ActiveSupport::ContinuousIntegration` class to Rails 5.2–7.x. Users install the gem, run `rails generate rails_local_ci:install` to copy `bin/ci` and `config/ci.rb` into their app, then run `./bin/ci` locally. When they upgrade to Rails 8.1, they simply remove the gem—no code changes needed, because the load path (`active_support/continuous_integration`) is identical.

## Commands

```bash
bundle install                                          # Install dependencies
bundle exec ruby test/continuous_integration_test.rb   # Run tests
```

## Architecture

```
lib/
  rails_local_ci.rb                                    # Entry point; requires core class + Railtie
  active_support/continuous_integration.rb             # Core DSL class (the main implementation)
  active_support/continuous_integration/group.rb       # Parallel group executor
  rails_local_ci/railtie.rb                            # Rails integration; registers generator
  generators/rails_local_ci/
    install_generator.rb                               # Copies templates into user's app
    templates/
      bin_ci                                           # Template: executable CI runner script
      config_ci.rb                                     # Template: example CI workflow config
test/
  continuous_integration_test.rb                       # Minitest suite
```

**`ActiveSupport::ContinuousIntegration`** is the core class. Key public methods:
- `self.run(title, subtitle, &block)` — main entry point; sets `ENV["CI"]="true"`, aborts on failure
- `run(title, subtitle, &block)` — instance method; prints heading, executes block, prints result line, aborts unless success
- `step(title, *command)` — runs a shell command, tracks pass/fail + timing, aborts if failing fast
- `group(name, parallel: 1, &block)` — groups steps; runs sequentially when `parallel <= 1`, or spawns a thread pool via `Group` when `parallel > 1`
- `success?` — true if all steps passed (`results` stores `[success_bool, title]` tuples)
- `report_step(title, command, &block)` — `:nodoc:` hook used by `Group` to record results and print output
- `colorize(text, type)` — `:nodoc:` returns ANSI-colored string; used by `Group` for progress display
- `fail_fast?` / `failing_fast?` — `:nodoc:` checks ARGV for `-f`/`--fail-fast` and whether any failure exists

**`ActiveSupport::ContinuousIntegration::Group`** handles parallel execution:
- Collects tasks via `TaskCollector` DSL (supports `step` and nested sequential `group`)
- Spawns a thread pool of size `parallel`; each thread dequeues and executes tasks
- Captures output per-step via PTY (preferred, retains colors) or Open3 (fallback)
- Writes captured output to temp files (`ci-*.log` in `Dir.tmpdir`), replays them in order after each step, then deletes them
- Shows a live cyan progress line (refreshed every 100ms) with running step names and elapsed time
- Restores the previous INT signal handler on completion

The load path placement (`active_support/continuous_integration`) is intentional—it allows the file to be required the same way Rails 8.1 provides it, making removal seamless.

## Implementation Sync

The gem tracks Rails `main`. Current implementation is synced to commit `10db73a0b6c4e3646ecc300c23e8a454ee72e02b`, which includes:
- **#54693** (Mar 2025): Original `ContinuousIntegration` class
- **#56049** (Oct 2025): Failure summary (`↳ Title failed`) at end of run
- **#56194** (Nov 2025): Fail-fast mode (`-f` / `--fail-fast`)
- **#56774** (Feb 2026): Parallel step groups (`group "Name", parallel: N`)

## Key Constraints

- The namespace `ActiveSupport::ContinuousIntegration` and load path `active_support/continuous_integration` must stay exactly as-is—changing them breaks the Rails 8.1 upgrade path.
- Supported Ruby: 2.4+. Avoid syntax or stdlib features unavailable in Ruby 2.4.
- Supported Rails: 5.2–7.x. Do not add dependencies that require Rails 8+.
- The gem has no runtime dependencies beyond Rails itself (no extra gems).
