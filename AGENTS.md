# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Purpose

A Ruby gem that backports `ActiveSupport::ContinuousIntegration` (as it exists on Rails `main`) to Rails 5.2–8.1. Users install the gem, run `rails generate rails_local_ci:install` to copy `bin/ci` and `config/ci.rb` into their app, then run `./bin/ci` locally. When they upgrade to Rails 8.2, they simply remove the gem—no code changes needed, because the load path (`active_support/continuous_integration`) is identical. Rails 8.1.x ships only the original March 2025 class (no `group`, fail-fast, or failure summary), so the gem is still supported on 8.1. There, Bundler places the gem's `lib` ahead of Active Support's, so the gem's copy shadows the built-in (verified for both explicit `require` and Active Support's `autoload :ContinuousIntegration`, with and without bootsnap). This relies on `bundler/setup` running before the class is first loaded; if Rails' copy is already required, the gem's copy cannot replace it.

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

The load path placement (`active_support/continuous_integration`) is intentional—it allows the file to be required the same way Rails 8.1 provides it, making removal seamless. Never rely on the built-in being absent; on Rails 8.1 both exist and the gem's copy must win via load-path order.

## Implementation Sync

The gem tracks Rails `main`. Current implementation is synced to commit `090f5408f4f81e78cd9232f274a8c2f3624a2b43`, which includes:
- **#54693** (Mar 2025): Original `ContinuousIntegration` class
- **#56049** (Oct 2025): Failure summary (`↳ Title failed`) at end of run
- **#56194** (Nov 2025): Fail-fast mode (`-f` / `--fail-fast`)
- **#56774** (Feb 2026): Parallel step groups (`group "Name", parallel: N`)
- Follow-ups through Nov 2026: `COLORS` frozen, unused `name` param removed from `Group#execute_group`, fail-fast parallel test stabilized. Upstream RDoc→Markdown comment conversion intentionally not ported.

## Key Constraints

- The namespace `ActiveSupport::ContinuousIntegration` and load path `active_support/continuous_integration` must stay exactly as-is—changing them breaks the Rails upgrade path.
- Supported Ruby: 2.4+. Avoid syntax or stdlib features unavailable in Ruby 2.4.
- Supported Rails: 5.2–8.1 (`< 8.2`). Do not add dependencies that require Rails 8+. Bump the upper bound only after checking that the next Rails release ships every DSL feature this gem provides.
- The gem has no runtime dependencies beyond Rails itself (no extra gems).
