require "pathname"

class ::RailsTemplate < Thor::Group
  include Thor::Actions
  include Rails::Generators::Actions

  attr_accessor :options

  def self.source_root
    File.join(__dir__, "templates")
  end

  def copy_gemfile
    remove_file "Gemfile"
    template "Gemfile.erb", "Gemfile"
  end

  def copy_controller_files
    remove_file "app/controllers/application_controller.rb"
    directory "app/controllers"
    remove_file "app/controllers/concerns/.keep"
  end

  def setup_assets
    remove_dir "app/assets"
    remove_dir "lib/assets"
    remove_file "package.json"
    remove_file "config/initializers/assets.rb"

    template "package.json.erb", "package.json"
    directory "app/frontend/images"
    directory "app/frontend/scripts"
    directory "app/frontend/styles"
    template "app/frontend/application.js.erb", "app/frontend/application.js"

    directory "config/webpack"
  end

  def copy_rc_files
    copy_file ".editorconfig"
    template ".rubocop.yml.erb", ".rubocop.yml"
    copy_file ".babelrc"
    copy_file ".eslintrc"
    copy_file ".eslintrc.development"
  end

  def copy_routes
    remove_file "config/routes.rb"
    template "config/routes.erb", "config/routes.rb"
  end

  def configure_env
    template ".env.development.erb", ".env.development"
    template ".env.test.erb", ".env.test"
    template "config/config.erb", "config/config.rb"
    template "asset_host.erb", "config/initializers/asset_host.rb"
    append_file "config/boot.rb", <<-RUBY.strip_heredoc

      # Load configuration
      require "env_vars/dotenv"
      require File.expand_path("../config", __FILE__)
    RUBY
  end

  def configure_ssl
    append_file "config/puma.rb", <<-RUBY.strip_heredoc

      if @options[:environment] == "development"
        ssl_bind "127.0.0.1", ENV.fetch("PORT", 3000), {
          key: "config/ssl/localhost.key",
          cert: "config/ssl/localhost.crt"
        }
      end
    RUBY

    directory "config/ssl"
  end

  def configure_database
    return if skip_active_record?

    remove_file "config/database.yml"
    template "config/database.erb", "config/database.yml"
  end

  def configure_test
    return if skip_test_unit?

    remove_file "test/test_helper.rb"
    copy_file "test/test_helper.rb"
    copy_file "test/support/minitest.rb"
    copy_file "test/support/fixtures.rb"
  end

  def configure_generators
    template "config/initializers/generators.erb",
             "config/initializers/generators.rb"
  end

  def configure_localization
    file = "config/initializers/localization.rb"
    template file, file
  end

  def configure_gitignore
    remove_file ".gitignore"
    copy_file ".gitignore"
  end

  def copy_procfile
    copy_file "Procfile"
  end

  def copy_view_files
    layout_path = "app/views/layouts/application.html.erb"
    remove_file layout_path
    template layout_path, layout_path

    view = "app/views/pages/home.html.erb"
    copy_file view, view
  end

  def configure_lograge
    copy_file "config/initializers/lograge.rb"
  end

  def copy_bin_scripts
    remove_file "bin/setup"
    copy_file "bin/setup"
    copy_file "bin/setup.Darwin"
    copy_file "bin/start-dev"
    run "chmod +x bin/*"
  end

  def install_deps
    inside(destination_root) do
      run "./bin/setup"
    end
  end

  def export_assets
    run "webpack --config ./config/webpack/development.js"
  end

  private

  def edge?
    options[:edge]
  end

  def dev?
    options[:dev]
  end

  def skip_active_record?
    options[:skip_active_record]
  end

  def skip_test_unit?
    options[:skip_test_unit]
  end

  def skip_bootsnap?
    options[:skip_bootsnap]
  end

  def postgresql?
    !skip_active_record? && database_adapter == "postgresql"
  end

  def app_const
    options[:app_name].camelize
  end

  def database_adapter
    {
      "mysql"      => "mysql2",
      "postgresql" => "pg",
      "postgres"   => "pg",
      "sqlite3"    => "sqlite3"
    }.fetch(options[:database])
  end

  def database_url(env)
    database_name = "#{options[:app_name]}_#{env}"

    case database_adapter
    when "sqlite3"
      %[sqlite3:db/#{env}.sqlite3]
    when "mysql"
      %[mysql2://root@localhost/#{database_name}]
    else
      %[postgres:///#{database_name}]
    end
  end

  def ruby_version
    {
      full: RUBY_VERSION,
      major: RUBY_VERSION[/^(\d+\.\d+)\..*?$/, 1]
    }
  end

  def rails_version
    [Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join(".")
  end
end

def check_or_die!(config_name, expected, message)
  return if options[config_name] == expected
  $stderr << "\n=> ERROR: #{message}\n"
  exit 1
end

check_or_die! "skip_javascript", true, "Please provide --skip-javascript (this template uses webpack to handle assets)"
check_or_die! "skip_sprockets", true, "Please provide --skip-sprockets (this template uses webpack to handle assets)"

generator = ::RailsTemplate.new
generator.shell = shell
generator.options = options.merge(app_name: app_name, rails_generator: self)
generator.destination_root = Dir.pwd
generator.invoke_all
