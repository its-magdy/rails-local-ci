# rails-local-ci

> Backport of Rails 8.1's `ActiveSupport::ContinuousIntegration` for Rails 5.2–7.x

Rails 8.1 introduced a standardized `bin/ci` script and `ActiveSupport::ContinuousIntegration` class ([PR #54693](https://github.com/rails/rails/pull/54693)) that runs the same CI steps locally and in the cloud. This gem ships that class for apps on Rails 5.2–7.x so you don't have to wait for an upgrade.

When you do upgrade to Rails 8.1, remove the gem — `bin/ci` and `config/ci.rb` stay unchanged because Rails 8.1 provides the class at the same load path.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [DSL Reference](#dsl-reference)
- [Fail-Fast Mode](#fail-fast-mode)
- [Commit Signoff](#commit-signoff)
- [CI Integration](#ci-integration)
- [Running Tests](#running-tests)
- [Upgrading to Rails 8.1](#upgrading-to-rails-81)
- [Compatibility](#compatibility)
- [How It Works](#how-it-works)
- [License](#license)

---

## Prerequisites

- Ruby >= 2.4
- Rails >= 5.2 and < 8.1

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
    # Optional: post a green commit status to unblock PR merge — see Commit Signoff below.
    # step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"     # GitHub
    # step "Signoff: All systems go. Ready for merge and deploy.", "bb-signoff"     # Bitbucket
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

`CI.run` accepts optional title and subtitle overrides:

```ruby
CI.run "My App CI", "Linting, security, and tests" do
  # ...
end
```

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

Install [`bb-signoff`](https://github.com/Mohamed-Omar96/bb-signoff):

```bash
curl -fsSL https://raw.githubusercontent.com/Mohamed-Omar96/bb-signoff/main/bb-signoff \
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

## Upgrading to Rails 8.1

1. Remove `gem "rails-local-ci"` from your `Gemfile`
2. Run `bundle install`

`bin/ci` and `config/ci.rb` require no changes. Rails 8.1 ships `ActiveSupport::ContinuousIntegration` at the same load path this gem uses.

---

## Compatibility

| Rails | Ruby  | Status |
|-------|-------|--------|
| 7.2   | 3.1+  | Tested |
| 7.1   | 3.0+  | Compatible |
| 7.0   | 2.7+  | Compatible |
| 6.1   | 2.7+  | Compatible |
| 6.0   | 2.7+  | Compatible |
| 5.2   | 2.4+  | Compatible |
| 8.1+  | —     | Use built-in — remove this gem |

---

## How It Works

The gem places `ActiveSupport::ContinuousIntegration` at `lib/active_support/continuous_integration.rb` — the identical load path Rails 8.1 uses. The generated `bin/ci` does:

```ruby
require_relative "../config/boot"
require "active_support/continuous_integration"  # resolved by this gem, or Rails 8.1 built-in

CI = ActiveSupport::ContinuousIntegration
require_relative "../config/ci.rb"
```

The generator copies only `bin/ci` and `config/ci.rb` into your app. The class itself lives in the gem.

---

## License

[MIT](LICENSE)
