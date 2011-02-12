require 'shellwords'
require 'fileutils'
require 'erb'
require 'bundler'
Bundler::GemHelper.install_tasks

if RUBY_PLATFORM[/darwin/]
  desc '[PORT=9999] Compile included AppleScript and place in ~/Library/Scripts/'
  task :applescript do
    @port   = ENV['PORT'] || 9999
    buf     = ERB.new(File.read 'extra/editserver.applescript.erb').result(binding)
    outfile = File.expand_path '~/Library/Scripts/editserver.scpt'

    puts "Writing #{outfile}"
    FileUtils.mkdir_p File.dirname(outfile)
    system "echo #{buf.shellescape} | osacompile -o #{outfile.shellescape}"
  end
end
