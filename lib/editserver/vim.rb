require 'editserver/editor'

class Editserver
  class Vim < Editor
    define_editor 'vim', '--servername', 'editserver'

    def server_available?
      %x(#{[*self.class.command, '--serverlist'].shelljoin}).split("\n").map do |l|
        l.strip.downcase
      end.include? 'editserver'
    end

    # FIXME: this shouldn't be hard-coded
    def open_term
      pid = fork { exec '/opt/nerv/bin/rxvt-unicode -r -- -e vim --servername editserver' }
      sleep 2 # HACK
      Process.detach pid
    end

    def edit file
      open_term unless server_available?
      super
    end
  end
end
