require 'optparse'
require 'yaml'
require 'rack'
require 'editserver'

class Editserver
  class Command
    def initialize args = []
      @args = args

      @opts = { :rcfile => "~/.#{File.basename $0}rc" }

      @rackopts = {
        :environment => 'development',
        :pid         => nil,
        :Port        => 9999,
        :Host        => '127.0.0.1',
        :AccessLog   => [],
        :config      => ''
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

        opt.on '--rc PATH', "Path to rc file; #{@opts[:rcfile]} by default",
               '(Also can be set by exporting EDITSERVERRC to environment)' do |arg|
          @opts[:rcfile] = File.expand_path arg
        end

        opt.on '--no-rc', "Suppress reading of rc file" do
          @opts[:norcfile] = true
        end
      end
    end

    def rcopts
      @rcopts ||= if @opts[:norcfile]
        {}
      else
        YAML.load_file File.expand_path(ENV['EDITSERVERRC'] || @opts[:rcfile])
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

    def server
      # HACK: Fixed in master -- remove when upgrading min rack dependency
      # http://groups.google.com/group/rack-devel/browse_thread/thread/8f6c3b79c99809ee
      srv = Rack::Server.new rackopts
      srv.instance_variable_set :@app, Editserver.new
      srv
    end

    def run
      options.parse @args
      $0 = 'editserver'
      server.start
    end
  end
end
