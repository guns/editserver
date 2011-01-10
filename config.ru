require 'bundler/setup'
require File.expand_path('../application.rb', __FILE__)

[$stdout, $stderr].each { |io| io.reopen 'vimserver.log', 'w' }

use Rack::Reloader, 1 unless ENV['RACK_ENV'] == 'production'
use Rack::Logger
run VimServer.new
