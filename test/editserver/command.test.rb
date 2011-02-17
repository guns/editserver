$:.unshift File.expand_path('../../lib', __FILE__)

require 'tempfile'
require 'yaml'
require 'rack/server'
require 'editserver/command'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'

describe Editserver::Command do
  before { @cmd = Editserver::Command.new ['--no-rc'] }

  describe :initialize do
    it 'should take a single optional argument' do
      Editserver::Command.method(:initialize).arity.must_equal -1
    end

    it 'should set internal state' do
      @cmd.instance_variable_get(:@args).must_equal ['--no-rc']
      @cmd.instance_variable_get(:@opts).must_equal(:rcfile => '~/.editserverrc')
      @cmd.instance_variable_get(:@editoropts).must_equal('default' => nil, 'terminal' => nil)
      @cmd.instance_variable_get(:@rackopts).keys.sort_by(&:to_s).must_equal [
        :Host, :Port, :Logger, :AccessLog, :pid, :config, :environment
      ].sort_by(&:to_s)
    end
  end

  describe :options do
    it 'should return an OptionParser object' do
      @cmd.options.must_be_kind_of OptionParser
    end

    it 'should modify internal state when parsing a list of arguments' do
      @cmd.options.parse %w[--host 0.0.0.0]
      @cmd.instance_variable_get(:@rackopts)[:Host].must_equal '0.0.0.0'

      @cmd.options.parse %w[--port 1000]
      @cmd.instance_variable_get(:@rackopts)[:Port].must_equal 1000

      @cmd.options.parse %w[--quiet]
      @cmd.instance_variable_get(:@opts)[:quiet].must_equal true
      @cmd.instance_variable_get(:@rackopts)[:Logger].level.must_equal WEBrick::BasicLog::FATAL - 1
      @cmd.instance_variable_get(:@rackopts)[:environment].must_equal 'none'

      @cmd.options.parse %w[--terminal xterm]
      @cmd.instance_variable_get(:@editoropts)['terminal'].must_equal 'xterm'

      @cmd.options.parse %w[--rc /dev/null]
      @cmd.instance_variable_get(:@opts)[:rcfile].must_equal '/dev/null'

      @cmd.options.parse %w[--no-rc]
      @cmd.instance_variable_get(:@opts)[:norcfile].must_equal true
    end
  end

  describe :say do
    it 'should write to $stdout unless --quiet option is specified' do
      capture_io { @cmd.say 'AHHHHHH!' }.first.must_equal "AHHHHHH!\n"
      @cmd.instance_variable_get(:@opts)[:quiet] = true
      capture_io { @cmd.say 'AHHHHHH!' }.first.must_equal ''
    end
  end

  describe :rcopts do
    before do
      @rcfile = Tempfile.new 'editserverrc'
      @cmd.instance_variable_get(:@opts)[:rcfile] = @rcfile.path
    end

    after { (@rcfile.close; @rcfile.unlink) if @rcfile.path }

    it 'should load the YAML file specified at @opts[:rcfile]' do
      opts = { 'editor' => { 'default' => 'emacs', 'terminal' => 'xterm' }, 'rack' => { 'port' => 1000 } }
      @rcfile.write opts.to_yaml
      @rcfile.rewind
      @cmd.rcopts.must_equal opts
    end

    it 'should create any missing top level keys' do
      @rcfile.write({ 'foo' => 'bar' }.to_yaml)
      @rcfile.rewind
      @cmd.rcopts.must_equal 'foo' => 'bar', 'rack' => {}, 'editor' => {}
    end

    it 'should return bare options if --no-rc is specified' do
      opts = { 'editor' => { 'default' => 'emacs', 'terminal' => 'xterm' }, 'rack' => { 'port' => 1000 } }
      @rcfile.write opts.to_yaml
      @rcfile.rewind
      @cmd.instance_variable_get(:@opts)[:norcfile] = true
      @cmd.rcopts.must_equal 'rack' => {}, 'editor' => {}
    end

    it 'should return bare options if rcfile does not exist' do
      opts = { 'editor' => { 'default' => 'emacs', 'terminal' => 'xterm' }, 'rack' => { 'port' => 1000 } }
      @rcfile.write opts.to_yaml
      @rcfile.rewind
      @rcfile.close
      @rcfile.unlink
      @cmd.rcopts.must_equal 'rack' => {}, 'editor' => {}
    end
  end # rcopts

  describe :rackopts do
    it 'should return @rackopts masked with @rcopts' do
      @cmd.instance_variable_get(:@opts)[:rcfile] = '/dev/null'
      @cmd.rackopts[:Port].must_equal 9999
      @cmd.rackopts[:Host].must_equal '127.0.0.1'
      @cmd.instance_variable_get(:@rcopts).merge!('rack' => { 'port' => 65535, 'host' => '1.1.1.1' })
      @cmd.rackopts[:Port].must_equal 65535
      @cmd.rackopts[:Host].must_equal '1.1.1.1'
    end
  end

  describe :editoropts do
    it 'should return @editoropts masked with @rcopts' do
      @cmd.instance_variable_get(:@opts)[:rcfile] = '/dev/null'
      @cmd.editoropts['default'].must_equal nil
      @cmd.editoropts['terminal'].must_equal nil
      @cmd.instance_variable_get(:@rcopts).merge!('editor' => { 'default' => 'pony', 'terminal' => 'sparkles' })
      @cmd.editoropts['default'].must_equal 'pony'
      @cmd.editoropts['terminal'].must_equal 'sparkles'
    end
  end

  describe :server do
    it 'should return an instance of Rack::Server' do
      @cmd.server.must_be_kind_of Rack::Server
    end

    it 'should pass rack options to new server instance' do
      @cmd.rcopts['rack']['port'] = 4000
      @cmd.server.options[:Port].must_equal 4000
      @cmd.rcopts['rack']['pid'] = '/dev/null'
      @cmd.server.options[:pid].must_equal '/dev/null'
    end

    it "should set the server's @app to an instance of Editserver" do
      @cmd.server.app.must_be_kind_of Editserver
    end
  end

  describe :run do
    before { @rd, @wr = IO.pipe }

    it 'should parse the arguments stored in @args' do
      @cmd.instance_variable_set :@args, ['--help']

      pid = fork do
        @rd.close
        $stdout.reopen @wr
        @cmd.run
      end

      @wr.close
      Process.wait2(pid).last.exitstatus.must_equal 0
      @rd.read.must_match /Usage:.*--help/m
    end

    it 'should start the server, and shutdown on SIGINT' do
      pid = fork do
        @rd.close
        $stdout.reopen @wr
        @cmd.run
      end

      @wr.close

      # data on pipe means the server is done initializing
      if IO.select [@rd]
        Process.kill :INT, pid
        Process.wait pid
        @rd.read.must_match /Listening.*#{@cmd.rackopts[:Host]}:#{@cmd.rackopts[:Port]}/
      end
    end
  end
end
