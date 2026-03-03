require "rails/railtie"

module RailsLocalCi
  class Railtie < Rails::Railtie
    generators do
      require "generators/rails_local_ci/install_generator"
    end
  end
end
