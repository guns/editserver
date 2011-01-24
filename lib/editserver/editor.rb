require 'shellwords'

class Editserver
  class Editor
    class << self

      def define_editor editor, *params
        self.class.instance_eval do
          bin = %x(which #{editor}).chomp
          raise RuntimeError, "#{editor} not found!" unless File.executable? bin

          # class attribute: Vim.command # => ['vim']
          attr_accessor :command
          self.command = [bin, *params]
        end

        define_method editor do |*args|
          out = %x(#{[*self.class.command, *args].shelljoin} 2>&1).chomp

          if $?.exitstatus.zero?
            out
          else
            raise EditError, out
          end
        end

        define_method :edit do |file|
          send editor, file
        end
      end

    end
  end
end
