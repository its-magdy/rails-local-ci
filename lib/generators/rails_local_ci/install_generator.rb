require "rails/generators"

module RailsLocalCi
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    desc "Install Local CI: copies bin/ci and config/ci.rb into your Rails app"

    def copy_ci_binstub
      copy_file "bin_ci", "bin/ci"
      chmod "bin/ci", 0755
    end

    def copy_ci_config
      copy_file "config_ci.rb", "config/ci.rb"
    end

    def show_readme
      say "\n✅ Local CI installed!", :green
      say "   Run: ./bin/ci", :cyan
    end
  end
end
