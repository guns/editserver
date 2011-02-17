$:.unshift File.expand_path('../../lib', __FILE__)

require 'tempfile'
require 'yaml'
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

      @cmd.options.parse %w[--terminal xterm]
      @cmd.instance_variable_get(:@editoropts)['terminal'].must_equal 'xterm'

      @cmd.options.parse %w[--rc /dev/null]
      @cmd.instance_variable_get(:@opts)[:rcfile].must_equal '/dev/null'

      @cmd.options.parse %w[--no-rc]
      @cmd.instance_variable_get(:@opts)[:norcfile].must_equal true
    end
  end

  describe :rcfile_accessors do
    before do
      @rcfile = Tempfile.new 'editserverrc'
      @cmd.instance_variable_get(:@opts)[:rcfile] = @rcfile.path
    end

    after { (@rcfile.close; @rcfile.unlink) if @rcfile.path }

    describe :rcopts do
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
    end

    describe :rackopts do
    end

    describe :editoropts do
    end
  end

  describe :server do
  end

  describe :run do
  end
end
