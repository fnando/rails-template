ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"

Dir["./test/support/**/*.rb"].each {|file| require file }
