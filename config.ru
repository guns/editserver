require 'bundler/setup'
require File.expand_path('../application.rb', __FILE__)

[$stdout, $stderr].each { |io| io.reopen 'editserver.log', 'a' }

use Rack::Reloader, 1 unless ENV['RACK_ENV'] == 'production'
use Rack::CommonLogger
run EditServer.new
