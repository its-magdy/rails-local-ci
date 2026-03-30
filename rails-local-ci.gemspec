Gem::Specification.new do |spec|
  spec.name          = "rails-local-ci"
  spec.version       = "0.1.1"
  spec.authors       = ["Mohamed Magdy Omar"]
  spec.email         = ["mm.medany96@gmail.com"]
  spec.summary       = "Backport of Rails 8.1 Local CI (ActiveSupport::ContinuousIntegration) for Rails 5.2–7.x"
  spec.description   = "Ships ActiveSupport::ContinuousIntegration and a generator that installs bin/ci + config/ci.rb. " \
                       "Any Rails 6/7 app can `gem 'rails-local-ci'` and get the same Local CI DX as Rails 8.1 built-in. " \
                       "Upgrading to Rails 8.1 later = just remove the gem, zero code changes."
  spec.homepage      = "https://github.com/its-magdy/rails-local-ci"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "rails", ">= 5.2", "< 8.1"
end
