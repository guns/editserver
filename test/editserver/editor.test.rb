$:.unshift File.expand_path('../../lib', __FILE__)
$:.unshift File.dirname(__FILE__)

require 'editserver'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'

describe Editserver::Editor do
end
