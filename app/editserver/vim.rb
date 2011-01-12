require 'shellwords'

class EditServer
  class Vim
    def vim *args
      @@vim ||= begin
        bin = %x(which vim).chomp
        raise EditError, 'Vim not found!' unless File.executable? bin
        bin
      end

      cmd = [@@vim, *args]
      out = %x(#{cmd.shelljoin} 2>&1).chomp

      if $?.exitstatus.zero?
        out
      else
        raise EditError, out
      end
    end

    def server_available?
      vim('--serverlist').split("\n").map { |l| l.strip.downcase }.include? 'editserver'
    end

    def edit file
      if server_available?
        vim '--servername', 'editserver', '--remote-tab-wait', file
        File.read file
      else
        raise EditError, 'No Vim server available!'
      end
    end
  end
end
