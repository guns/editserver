require 'shellwords'

if RUBY_PLATFORM[/darwin/]
  desc 'Compile included AppleScript and place in ~/Library/Scripts/'
  task :applescript do

    infile  = 'extra/editserver.applescript'
    outfile = 'extra/editserver.scpt'
    cmd     = ['osacompile', '-o', outfile, infile]

    puts cmd.shelljoin
    system *cmd
  end
end
