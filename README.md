# rails-local-ci

[![Gem version](https://img.shields.io/gem/v/rails-local-ci)](https://rubygems.org/gems/rails-local-ci)
[![Gem downloads](https://img.shields.io/gem/dt/rails-local-ci)](https://rubygems.org/gems/rails-local-ci)
[![CI](https://github.com/its-magdy/rails-local-ci/actions/workflows/ci.yml/badge.svg)](https://github.com/its-magdy/rails-local-ci/actions/workflows/ci.yml)

> Backport of Rails' `ActiveSupport::ContinuousIntegration` (as on Rails `main`) for Rails 5.2–8.1

Rails 8.1 introduced a standardized `bin/ci` script and `ActiveSupport::ContinuousIntegration` class ([PR #54693](https://github.com/rails/rails/pull/54693)) that runs the same CI steps locally and in the cloud. This gem ships that class for apps on Rails 5.2–8.1 so you don't have to wait for an upgrade.

The gem tracks Rails `main`, so it also includes features that came after 8.1 shipped: parallel `group`s, fail-fast mode, and the end-of-run failure summary. Rails 8.1.x doesn't have them, so the gem is useful on 8.1 too.

Once you upgrade to Rails 8.2, remove the gem. `bin/ci` and `config/ci.rb` stay unchanged because Rails provides the class at the same load path.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [DSL Reference](#dsl-reference)
- [Parallel Groups](#parallel-groups)
- [Fail-Fast Mode](#fail-fast-mode)
- [Commit Signoff](#commit-signoff)
- [CI Integration](#ci-integration)
- [Running Tests](#running-tests)
- [Upgrading to Rails 8.2](#upgrading-to-rails-82)
- [Compatibility](#compatibility)
- [How It Works](#how-it-works)
- [License](#license)

---

## Prerequisites

- Ruby >= 2.4
- Rails >= 5.2 and < 8.2

---

## Installation

Add to your `Gemfile`:

```ruby
gem "rails-local-ci"
```

Install:

```bash
bundle install
```

Run the generator:

```bash
rails generate rails_local_ci:install
```

The generator copies two files into your app:

- `bin/ci` — the runner script (set to executable)
- `config/ci.rb` — your CI step definitions

---

## Usage

Run all CI steps locally:

```bash
./bin/ci
```

Expected output:

```
Continuous Integration
Running tests, style checks, and security audits

Setup
bin/setup --skip-server

✅ Setup passed in 2.31s

Style: Ruby
bin/rubocop

✅ Style: Ruby passed in 1.04s

Tests: Rails
bin/rails test

✅ Tests: Rails passed in 4.17s

✅ Continuous Integration passed in 8.34s
```

Define your steps in `config/ci.rb`:

```ruby
CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby",                      "bin/rubocop"        if File.exist?("bin/rubocop")
  step "Security: Gem audit",              "bin/bundler-audit"  if File.exist?("bin/bundler-audit")
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error" if File.exist?("bin/brakeman")
  step "Tests: Rails",                     "bin/rails test"

  if success?
    heading "All CI checks passed!", "Your changes are ready for review"
  else
    failure "CI checks failed", "Fix the issues above before submitting your PR"
  end
end
```

`CI.run` sets `ENV["CI"] = "true"` for the duration of the run, which Rails uses to enable eager loading and disable verbose logging.

---

## DSL Reference

All methods are available inside the `CI.run do ... end` block in `config/ci.rb`.

| Method | Description |
|--------|-------------|
| `step "Title", "command"` | Run a shell command; records pass/fail and elapsed time |
| `step "Title", "cmd", "arg1", "arg2"` | Run with multiple args — passed directly to `system`, correctly shell-escaped |
| `group "Title" do ... end` | Group steps visually; runs sequentially |
| `group "Title", parallel: N do ... end` | Run up to N steps concurrently in threads |
| `success?` | Returns `true` if every step so far has passed |
| `heading "Title"` | Print a green banner |
| `heading "Title", "Subtitle"` | Print a green banner with a gray subtitle; accepts `padding: false` to suppress blank lines |
| `failure "Title", "Subtitle"` | Print a red error banner |
| `echo "Text", type: :success` | Print colorized text to the terminal |

**Color types for `echo` and `heading`:**

| Type | Color |
|------|-------|
| `:banner` | Green (bold) |
| `:title` | Purple (bold) |
| `:subtitle` | Gray (bold) |
| `:error` | Red (bold) |
| `:success` | Green (bold) |
| `:progress` | Cyan (bold) |

`CI.run` accepts optional title and subtitle overrides:

```ruby
CI.run "My App CI", "Linting, security, and tests" do
  # ...
end
```

---

## Parallel Groups

Run multiple independent steps concurrently using `group`:

```ruby
CI.run do
  step "Setup", "bin/setup --skip-server"

  group "Checks", parallel: 3 do
    step "Style: Ruby",        "bin/rubocop"
    step "Security: Brakeman", "bin/brakeman --quiet"
    step "Security: Gems",     "bin/bundler-audit"
  end

  step "Tests: Rails", "bin/rails test"
end
```

`parallel: N` runs up to N steps in concurrent threads. Output is captured per-step (via PTY when available, Open3 otherwise) and displayed in declaration order after all steps complete — no interleaving. A live progress indicator shows which steps are running.

`group` without `parallel:` (or `parallel: 1`) runs steps sequentially, useful for visual grouping.

**Nested groups**: a `group` inside a parallel group runs its steps sequentially within that thread slot. Sub-groups cannot themselves be parallelized — attempting to set `parallel:` on a nested group raises `ArgumentError`.

---

## Fail-Fast Mode

Stop at the first failing step instead of running all steps:

```bash
./bin/ci --fail-fast
./bin/ci -f
```

---

## Commit Signoff

After a successful local CI run, post a green commit status directly to your Git host to unblock PR merge — no cloud CI runner needed.

### GitHub

Requires the [`gh` CLI](https://cli.github.com) and the `gh-signoff` extension:

```bash
gh extension install basecamp/gh-signoff
```

Add to `config/ci.rb`:

```ruby
if success?
  step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
end
```

### Bitbucket

Install [`bb-signoff`](https://github.com/its-magdy/bb-signoff):

```bash
curl -fsSL https://raw.githubusercontent.com/its-magdy/bb-signoff/main/bb-signoff \
  -o /usr/local/bin/bb-signoff && chmod +x /usr/local/bin/bb-signoff
```

Create a Bitbucket repository access token with these scopes:
- Repositories: Read, Write, Admin
- Pull Requests: Read, Write

Store the token in `~/.bb-signoff` or export it as `BB_API_TOKEN`.

Add to `config/ci.rb`:

```ruby
if success?
  step "Signoff: All systems go. Ready for merge and deploy.", "bb-signoff"
end
```

---

## CI Integration

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bin/ci
```

### Bitbucket Pipelines

```yaml
pipelines:
  default:
    - step:
        name: CI
        script:
          - bundle install
          - bin/ci
```

---

## Running Tests

```bash
bundle exec ruby test/continuous_integration_test.rb
```

---

## Upgrading to Rails 8.2

1. Remove `gem "rails-local-ci"` from your `Gemfile`
2. Run `bundle install`

`bin/ci` and `config/ci.rb` require no changes. Rails 8.2 (in development on Rails `main` as of Nov 2026) ships `ActiveSupport::ContinuousIntegration` at the same load path this gem uses, with `group`, fail-fast, and the failure summary built in.

### Rails 8.1

Keep the gem on Rails 8.1. Rails 8.1.x (checked through 8.1.4) only ships the original `step`, `success?`, `heading`, `echo`, and `failure` DSL. Without the gem, a `config/ci.rb` that uses `group` fails with `NoMethodError`, and `-f` / `--fail-fast` is silently ignored. With the gem installed, its copy of the class takes precedence over the Rails 8.1 built-in, because Bundler puts the gem's `lib` ahead of Active Support's on the load path.

If you'd rather drop the gem on 8.1, replace each `group` block with the `step`s inside it, and stop relying on `-f`.

---

## Compatibility

| Rails | Ruby  | Status |
|-------|-------|--------|
| 8.1   | 3.2+  | Tested |
| 7.2   | 3.1+  | Tested |
| 7.1   | 3.0+  | Tested |
| 7.0   | 2.7+  | Compatible |
| 6.1   | 2.7+  | Compatible |
| 6.0   | 2.7+  | Compatible |
| 5.2   | 2.4+  | Compatible |
| 8.2+  | —     | Use built-in — remove this gem |

---

## How It Works

The gem places `ActiveSupport::ContinuousIntegration` at `lib/active_support/continuous_integration.rb` — the identical load path Rails uses. The generated `bin/ci` does:

```ruby
require_relative "../config/boot"
require "active_support/continuous_integration"  # resolved by this gem, or the Rails built-in once the gem is removed

CI = ActiveSupport::ContinuousIntegration
require_relative "../config/ci.rb"
```

The generator copies only `bin/ci` and `config/ci.rb` into your app. The class itself lives in the gem.

---

## License

[MIT](LICENSE)
