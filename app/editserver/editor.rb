require 'shellwords'

class EditServer
  class Editor
    class << self

      def define_editor editor, *params
        define_method editor do |*args|
          @@editor ||= begin
            bin = %x(which #{editor}).chomp
            raise EditError, "#{editor} not found!" unless File.executable? bin
            [bin, *params]
          end

          out = %x(#{[*@@editor, *args].shelljoin} 2>&1).chomp

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
