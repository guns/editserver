$:.unshift File.expand_path('../app', __FILE__)

require 'bundler/setup'
require 'editserver'

[$stdout, $stderr].each { |io| io.reopen 'editserver.log', 'a' }

use Rack::Reloader, 1 unless ENV['RACK_ENV'] == 'production'
use Rack::CommonLogger
run EditServer.new
