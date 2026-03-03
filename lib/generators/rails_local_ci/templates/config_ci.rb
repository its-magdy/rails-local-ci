# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby",                      "bin/rubocop"        if File.exist?("bin/rubocop")
  step "Security: Gem audit",              "bin/bundler-audit"  if File.exist?("bin/bundler-audit")
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error" if File.exist?("bin/brakeman")
  step "Tests: Rails",                     "bin/rails test"

  # Optional: set a green commit status to unblock PR merge.
  # GitHub: Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # Bitbucket: Install bb-signoff (https://github.com/Mohamed-Omar96/bb-signoff).
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"     # GitHub
  #   step "Signoff: All systems go. Ready for merge and deploy.", "bb-signoff"     # Bitbucket
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
