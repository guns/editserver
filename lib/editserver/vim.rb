require 'editserver/editor'

class Editserver
  class Vim < Editor
    define_editor 'vim', '--servername', 'editserver'

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
      vim '--remote-tab-wait', file
    end
  end
end
