$:.unshift File.expand_path('../lib', __FILE__)

require 'bundler/setup'
require 'editserver'

run Editserver.new
