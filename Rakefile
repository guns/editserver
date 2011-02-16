require 'shellwords'
require 'fileutils'
require 'erb'
require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :test

desc 'Run all tests'
task :test do
  Dir['test/**/*.test.rb'].each { |f| load f }
end

if RUBY_PLATFORM[/darwin/]
  $:.unshift File.expand_path('../lib', __FILE__)
  require 'editserver/command'

  @cmd = Editserver::Command.new

  desc "[PORT=#{@cmd.rackopts[:Port]}] Compile included AppleScript and place in ~/Library/Scripts/"
  task :applescript do
    @port   = ENV['PORT'] || @cmd.rackopts[:Port]
    buf     = ERB.new(File.read 'extra/editserver.applescript.erb').result(binding)
    outfile = File.expand_path '~/Library/Scripts/editserver.scpt'

    puts "Writing #{outfile}"
    FileUtils.mkdir_p File.dirname(outfile)
    system "echo #{buf.shellescape} | osacompile -o #{outfile.shellescape}"
  end
end
