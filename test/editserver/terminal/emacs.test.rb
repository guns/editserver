$:.unshift File.expand_path('../../../lib', __FILE__)

require 'editserver/terminal/emacs'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'
