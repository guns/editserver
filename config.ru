$:.unshift File.expand_path('../app', __FILE__)

require 'bundler/setup'
require 'editserver'

[$stdout, $stderr].each { |io| io.reopen 'editserver.log', 'a' }

use Rack::Logger
use Rack::CommonLogger
run EditServer.new
