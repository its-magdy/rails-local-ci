# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-02

### Changed

- Allow Rails 8.1 (`rails >= 5.2, < 8.2`). Rails 8.1.x lacks `group`, fail-fast, and the failure summary, so the gem now covers 8.1 apps; remove it when upgrading to Rails 8.2
- CI: added a Rails 8.1 appraisal; pinned the Rails 7.1 appraisal to `~> 7.1.0` (it previously resolved to 7.2)
- Synced `ActiveSupport::ContinuousIntegration` with Rails main @ 090f540: `COLORS` is now frozen; removed unused `name` parameter from `Group#execute_group` (internal)
- Stabilized the parallel-group fail-fast test (upstream rails/rails@d475d9b)
- README: documented Rails 8.1 support and the Rails 8.2 upgrade path
- Tests: added a check that the gem's copy wins on the load path over the Rails built-in; widened the parallel-group timing test margin to avoid CI flakes

### Security

- Require MFA for RubyGems pushes (`rubygems_mfa_required` gemspec metadata)
- Pin GitHub Actions to commit SHAs, disable persisted checkout credentials, and restrict default CI token permissions
- Add bundler-audit CI job, monthly Dependabot updates, and a SECURITY.md policy
- Patched vulnerable development dependencies in `Gemfile.lock` (Rails 8.0.5.1, nokogiri, rack, and others)
- Bumped `actions/checkout` to v7.0.1 and `softprops/action-gh-release` to v3.0.3

## [0.1.1] - 2026-03-30

### Changed

- Added MIT attribution headers to files adapted from Ruby on Rails, crediting David Heinemeier Hansson per the Rails MIT License

## [0.1.0] - 2026-03-29

### Added

- `ActiveSupport::ContinuousIntegration` backported from Rails 8.1
- `step` — run shell commands with pass/fail tracking and elapsed time
- `group` — sequential or parallel step groups (`parallel: N`)
- Fail-fast mode (`-f` / `--fail-fast`)
- Failure summary (`↳ Title failed`) printed at end of run
- Install generator: `rails generate rails_local_ci:install` copies `bin/ci` and `config/ci.rb` into your app
- Support for Ruby >= 2.4 and Rails 5.2–7.x

[0.2.0]: https://github.com/its-magdy/rails-local-ci/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/its-magdy/rails-local-ci/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/its-magdy/rails-local-ci/releases/tag/v0.1.0
