require 'shellwords'

class Editserver
  class Editor
    class << self
      attr_accessor :command

      def define_editor editor, *params
        @command = [%x(which #{editor}).chomp, *params]
      end

      @@terminal = nil

      def terminal
        @@terminal
      end

      def terminal= str
        @@terminal = case str
        when String   then str.shellsplit
        when NilClass then nil
        end
      end
    end # self

    def terminal
      @@terminal
    end

    def edit file
      cmd = self.class.command

      if not File.executable? cmd.first
        File.open(file, 'w') { |f| f.write "Editor not found: #{cmd.first.inspect}" }
        return
      end

      out = %x(#{(cmd + [file]).shelljoin} 2>&1).chomp

      if $?.exitstatus.zero?
        out
      else
        raise EditError, out
      end
    end
  end
end
