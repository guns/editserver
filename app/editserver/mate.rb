require 'shellwords'

class EditServer
  class Mate
    def mate *args
      @@mate ||= begin
        bin = '/Applications/TextMate.app/Contents/Resources/mate'
        raise EditError, 'Mate not found!' unless File.executable? bin
        bin
      end

      cmd = [@@mate, '-w', *args]
      out = %x(#{cmd.shelljoin} 2>&1).chomp

      if $?.exitstatus.zero?
        out
      else
        raise EditError, out
      end
    end

    def edit file
      mate file
      File.read file
    end
  end
end
