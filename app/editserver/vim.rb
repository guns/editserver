require 'editserver/editor'

class EditServer
  class Vim < Editor
    define_editor 'vim'

    def server_available?
      vim('--serverlist').split("\n").map { |l| l.strip.downcase }.include? 'editserver'
    end

    # FIXME: this shouldn't be hard-coded
    def open_term
      pid = fork { exec '/opt/nerv/bin/rxvt-unicode -r -- -e vim --servername editserver' }
      sleep 2 # HACK
      Process.detach pid
    end

    def edit file
      open_term unless server_available?

      vim '--servername', 'editserver', '--remote-tab-wait', file
      File.read file
    end
  end
end
