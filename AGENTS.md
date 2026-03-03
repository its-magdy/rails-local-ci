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
  rails_local_ci.rb                          # Entry point; requires core class + Railtie
  active_support/continuous_integration.rb   # Core DSL class (the main implementation)
  rails_local_ci/railtie.rb                  # Rails integration; registers generator
  generators/rails_local_ci/
    install_generator.rb                     # Copies templates into user's app
    templates/
      bin_ci                                 # Template: executable CI runner script
      config_ci.rb                           # Template: example CI workflow config
test/
  continuous_integration_test.rb             # Minitest suite
```

**`ActiveSupport::ContinuousIntegration`** is the core class. Key methods:
- `self.run(title, subtitle, &block)` — main entry point; sets `ENV["CI"]="true"`, aborts on failure
- `step(title, *command)` — runs a shell command and tracks pass/fail + timing
- `report(title, &block)` — executes a block and captures results
- `success?` — true if all steps passed

The load path placement (`active_support/continuous_integration`) is intentional—it allows the file to be required the same way Rails 8.1 provides it, making removal seamless.

## Key Constraints

- The namespace `ActiveSupport::ContinuousIntegration` and load path `active_support/continuous_integration` must stay exactly as-is—changing them breaks the Rails 8.1 upgrade path.
- Supported Ruby: 2.4+. Avoid syntax or stdlib features unavailable in Ruby 2.4.
- Supported Rails: 5.2–7.x. Do not add dependencies that require Rails 8+.
- The gem has no runtime dependencies beyond Rails itself (no extra gems).
