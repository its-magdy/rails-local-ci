Gem::Specification.new do |spec|
  spec.name          = "rails-local-ci"
  spec.version       = "0.2.0"
  spec.authors       = ["Mohamed Magdy Omar"]
  spec.email         = ["mm.medany96@gmail.com"]
  spec.summary       = "Backport of Rails Local CI (ActiveSupport::ContinuousIntegration, as on Rails main) for Rails 5.2–8.1"
  spec.description   = "Ships ActiveSupport::ContinuousIntegration and a generator that installs bin/ci + config/ci.rb. " \
                       "Any Rails 5.2–8.1 app can `gem 'rails-local-ci'` and get the full Local CI DX from Rails main (parallel groups, fail-fast, failure summary). " \
                       "Upgrading to Rails 8.2 later = just remove the gem, zero code changes."
  spec.homepage      = "https://github.com/its-magdy/rails-local-ci"
  spec.license       = "MIT"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"

  spec.files         = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "rails", ">= 5.2", "< 8.2"
end
