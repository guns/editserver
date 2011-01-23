require 'shellwords'
require 'fileutils'

if RUBY_PLATFORM[/darwin/]
  desc 'Compile included AppleScript and place in ~/Library/Scripts/'
  task :applescript do

    infile  = 'extra/editserver.applescript'
    outfile = File.expand_path '~/Library/Scripts/editserver.scpt'
    cmd     = ['osacompile', '-o', outfile, infile]

    FileUtils.mkdir_p File.basename(outfile)
    puts cmd.shelljoin
    system *cmd
  end
end
