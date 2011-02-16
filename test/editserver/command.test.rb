$:.unshift File.expand_path('../../lib', __FILE__)

require 'editserver/command'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'

describe Editserver::Command do
  describe :initialize do
    it 'should take a single optional argument' do
      Editserver::Command.method(:initialize).arity.must_equal -1
    end

    it 'should set internal state' do
      cmd = Editserver::Command.new ['--no-rc']
      cmd.instance_variable_get(:@args).must_equal ['--no-rc']
      cmd.instance_variable_get(:@opts).must_equal(:rcfile => '~/.editserverrc')
      cmd.instance_variable_get(:@editoropts).must_equal('default' => nil, 'terminal' => nil)
      cmd.instance_variable_get(:@rackopts).keys.sort.must_equal [
        :environment, :pid, :Port, :Host, :AccessLog, :config
      ].sort
    end
  end

  describe :options do
    before { @cmd = Editserver::Command.new ['--no-rc'] }

    it 'should return an OptionParser object' do
      @cmd.options.must_be_kind_of OptionParser
    end

    it 'should modify internal state when parsing a list of arguments' do
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

  #
  # TODO: finish tests
  #

  describe :rcopts do
  end

  describe :rackopts do
  end

  describe :editoropts do
  end

  describe :server do
  end

  describe :run do
  end
end
