require 'shellwords'

class Editserver
  class Editor
    class << self
      attr_accessor :command

      def define_editor editor, *params
        bin = %x(which #{editor}).chomp
        raise RuntimeError, "#{editor} not found!" unless File.executable? bin
        self.command = [bin, *params]
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
