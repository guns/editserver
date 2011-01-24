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
      end

    end

    def edit file
      File.open file, 'w' do |f|
        f.write %Q{\
          Missing: #{self.class}#edit

            * Should accept one argument (file to edit)
            * Should block until file is written (this is a nice time to open a editor)
            * Return value is discarded; raise EditError to return HTTP 500
        }.gsub(/^ {10}/, '')
      end
    end
  end
end
