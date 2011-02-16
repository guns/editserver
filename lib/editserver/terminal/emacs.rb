require 'editserver/editor'

class Editserver
  class Emacs < Editor
    define_editor *%w[emacsclient --alternate-editor='']

    def start_server
      pid = fork { exec *(terminal + %w[-e emacs --eval (server-start)]) }
      sleep 2 # HACK!
      Process.detach pid
    end

    def edit file
      if terminal.nil?
        File.open(file, 'w') { |f| f.write 'No terminal defined!' }
      else
        super
      end
    rescue EditError
      start_server
      super
    end
  end
end
