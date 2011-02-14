require 'shellwords'
require 'fileutils'
require 'erb'
require 'bundler'
require 'editserver/command'
Bundler::GemHelper.install_tasks

if RUBY_PLATFORM[/darwin/]
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
