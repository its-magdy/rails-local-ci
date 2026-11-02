# Security Policy

## Supported Versions

Only the latest released version of `rails-local-ci` receives security fixes.

## Reporting a Vulnerability

Please **do not** open a public issue for security problems.

Report vulnerabilities privately through GitHub's
[private vulnerability reporting](https://github.com/its-magdy/rails-local-ci/security/advisories/new).

You can expect an initial response within 7 days. Once a fix is ready, a patched
version will be released and the advisory published with credit to the reporter
(unless you prefer to remain anonymous).

Note: `rails-local-ci` executes the shell commands you declare in `config/ci.rb`
by design. Treat that file like any other executable code in your repository.
