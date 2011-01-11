class EditServer
  class Vim
    def initialize request
      @request = request
    end

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
      vim('--serverlist').split("\n").map { |l| l.strip.downcase }.include? 'vimserver'
    end

    # FIXME: files should be temporary; client should send extant text
    def edit name
      if server_available?
        file = "/tmp/editserver/#{name}"
        FileUtils.mkdir_p File.dirname(file), :mode => 0700
        File.open(file, 'a', 0600).close
        vim '--servername', 'vimserver', '--remote-tab-wait', file
        File.read file
      else
        raise EditError, 'No Vim server available!'
      end
    end
  end
end
