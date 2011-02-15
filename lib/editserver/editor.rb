require 'shellwords'

class Editserver
  class Editor
    class << self
      attr_accessor :command

      @@terminal = nil

      def define_editor editor, *params
        bin = %x(which #{editor}).chomp
        raise RuntimeError, "#{editor} not found!" unless File.executable? bin
        @command = [bin, *params]
      end

      def terminal
        @@terminal
      end

      def terminal= str
        @@terminal = str.shellsplit if str.is_a? String
      end
    end # self

    def edit file
      out = %x(#{[*self.class.command, file].shelljoin} 2>&1).chomp

      if $?.exitstatus.zero?
        out
      else
        raise EditError, out
      end
    end
  end
end
