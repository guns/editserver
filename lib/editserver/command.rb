require 'optparse'
require 'yaml'
require 'webrick/log'
require 'rack'
require 'editserver'

class Editserver
  class Command
    def initialize args = []
      @args = args
      @opts = { :rcfile => "~/.editserverrc" }

      # keys are strings because YAML.load returns string keys,
      # and we are not restricting the keys like @rackopts
      @editoropts = {
        'default'  => nil,
        'terminal' => nil
      }

      @rackopts = {
        :Host        => '127.0.0.1',
        :Port        => 9999,
        :Logger      => WEBrick::Log.new(nil, WEBrick::BasicLog::WARN), # be less chatty
        :AccessLog   => [], # rack does its own access logging, so keep this blank
        :pid         => nil,
        :config      => '',
        :environment => 'deployment'
      }
    end

    def options
      OptionParser.new do |opt|
        opt.summary_width = 20

        opt.banner = %Q(\
          Usage: #{File.basename $0} [options]

          Options:
        ).gsub /^ +/, ''

        opt.on '-p', '--port NUMBER', Integer, "default: #{rackopts[:Port]}" do |arg|
          @rackopts[:Port] = arg
        end

        opt.on '-t', '--terminal CMD', 'Terminal to launch for console editors' do |arg|
          @editoropts['terminal'] = arg
        end

        opt.on '--rc PATH', "Path to rc file; #{@opts[:rcfile]} by default",
               '(Also can be set by exporting EDITSERVERRC to environment)' do |arg|
          @rcopts = nil # reset cached user opts
          @opts[:rcfile] = File.expand_path arg
        end

        opt.on '--no-rc', 'Suppress reading of rc file' do
          @opts[:norcfile] = true
        end
      end
    end

    def rcopts
      @rcopts ||= begin
        empty  = { 'rack' => {}, 'editor' => {} }
        rcfile = File.expand_path ENV['EDITSERVERRC'] || @opts[:rcfile]

        if @opts[:norcfile]
          empty
        elsif File.exists? rcfile
          opts = YAML.load_file File.expand_path(rcfile)
          opts           ||= {}
          opts['rack']   ||= {}
          opts['editor'] ||= {}
          opts
        else
          empty
        end
      end
    end

    # returns dup of @rackopts masked by rcopts
    def rackopts
      (opts = @rackopts.dup).keys.each do |k|
        v = rcopts['rack'][k.to_s]
        v = rcopts['rack'][k.to_s.downcase] if v.nil? # be tolerant of lowercase keys
        opts[k] = v unless v.nil?
      end

      opts
    end

    # returns dup of @editoropts merged with rcopts
    def editoropts
      @editoropts.dup.merge rcopts['editor']
    end

    def server
      # HACK: Fixed in master -- remove when upgrading min rack dependency
      # http://groups.google.com/group/rack-devel/browse_thread/thread/8f6c3b79c99809ee
      srv = Rack::Server.new rackopts
      srv.instance_variable_set :@app, Editserver.new(editoropts)
      srv
    end

    def run
      options.parse @args
      $0 = 'editserver'
      puts banner
      server.start
    ensure
      puts fx("\nGoodbye!", [32,1])
    end

    private

    def banner
      %Q(\
                 __      __
                /\\ \\  __/\\ \\__
           __   \\_\\ \\/\\_\\ \\ ,_\\   ____     __   _ __   __  __     __   _ __
         /'__`\\ /'_` \\/\\ \\ \\ \\/  /',__\\  /'__`\\/\\`'__\\/\\ \\/\\ \\  /'__`\\/\\`'__\\
        /\\  __//\\ \\L\\ \\ \\ \\ \\ \\_/\\__, `\\/\\  __/\\ \\ \\/ \\ \\ \\_/ |/\\  __/\\ \\ \\/
        \\ \\____\\ \\___,_\\ \\_\\ \\__\\/\\____/\\ \\____\\\\ \\_\\  \\ \\___/ \\ \\____\\\\ \\_\\
         \\/____/\\/__,_ /\\/_/\\/__/\\/___/  \\/____/ \\/_/   \\/__/   \\/____/ \\/_/

        Listening on #{fx "#{rackopts[:Host]}:#{rackopts[:Port]}", [32,1]}\
      ).gsub(/^ {8}/, '')
    end

    def fx str, effects = []
      return str unless $stdout.tty?
      str.gsub /^(.*)$/, "\e[#{[effects].flatten.join ';'}m\\1\e[0m"
    end
  end
end
