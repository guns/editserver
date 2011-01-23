require 'shellwords'

class EditServer
  class Editor
    class << self

      def define_editor editor, *params
        define_method editor.to_sym do |*args|
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
      end

    end

    def edit file
      'Redefine the Editor#edit method.'
    end
  end
end

