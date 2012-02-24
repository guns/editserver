require 'editserver/editor'

class Editserver
  class Vim < Editor
    define_editor *%w[vim --servername EDITSERVER --remote-tab-wait]

    def server_available?
      %x(vim --serverlist).split("\n").map { |l| l.strip.upcase }.include? 'EDITSERVER'
    end

    def start_server
      pid = fork { exec *(terminal + %w[-e vim --servername EDITSERVER]) }
      Process.detach pid
    end

    def edit file
      if terminal.nil?
        File.open(file, 'w') { |f| f.write 'No terminal defined!' }
      else
        start_server unless server_available?
        sleep 0.1 until server_available?
        super
      end
    end
  end
end
