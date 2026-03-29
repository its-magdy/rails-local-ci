# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-29

### Added

- `ActiveSupport::ContinuousIntegration` backported from Rails 8.1
- `step` — run shell commands with pass/fail tracking and elapsed time
- `group` — sequential or parallel step groups (`parallel: N`)
- Fail-fast mode (`-f` / `--fail-fast`)
- Failure summary (`↳ Title failed`) printed at end of run
- Install generator: `rails generate rails_local_ci:install` copies `bin/ci` and `config/ci.rb` into your app
- Support for Ruby >= 2.4 and Rails 5.2–7.x

[0.1.0]: https://github.com/its-magdy/rails-local-ci/releases/tag/v0.1.0
