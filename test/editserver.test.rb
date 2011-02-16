$:.unshift File.expand_path('../../lib', __FILE__)
$:.unshift File.dirname(__FILE__)

require 'rack/mock'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'
require 'editserver'
require 'editserver/version'
require 'editserver/command'

describe Editserver do
  describe :VERSION do
    it 'should have a VERSION constant' do
      Editserver::VERSION.must_match /\d+\.\d+\.\d+/
    end
  end

  describe :ErrorClasses do
    it 'should have some custom error classes' do
      Editserver::EditError.new.must_be_kind_of StandardError
      Editserver::RoutingError.new.must_be_kind_of StandardError
    end
  end

  describe :GUI_EDITORS do
    it 'should be a Hash of string keys and string values' do
      Editserver::GUI_EDITORS.must_be_kind_of Hash
      Editserver::GUI_EDITORS.each do |k,v|
        k.must_be_kind_of String
        v.must_be_kind_of String
      end
    end
  end

  describe :editors do
    it 'should be a Hash of string keys and class values' do
      (srv = Editserver.new).editors.must_be_kind_of Hash
      srv.editors.each do |k,v|
        k.must_be_kind_of String
        v.must_be_kind_of Class
      end
    end
  end

  describe :initialize do
    it 'should optionally accept an options Hash' do
      Editserver.method(:initialize).arity.must_equal -1
      lambda { Editserver.new 'string' }.must_raise TypeError
    end

    it 'should not mutate passed options Hash' do
      Editserver.new(opts = { 'terminal' => 'xterm' })
      opts['terminal'].must_equal 'xterm'
    end

    it 'should set Editor::terminal' do
      Editserver.new 'terminal' => 'xterm -fg white'
      Editserver::Editor.terminal.must_equal %w[xterm -fg white] # gross; on the todo list
    end

    it 'should set @editors' do
      srv = Editserver.new
      { 'vim' => Editserver::Vim, 'emacs' => Editserver::Emacs }.each do |k,v|
        srv.editors[k].must_equal v
      end

      srv = Editserver.new 'kitten' => 'cat --with-qte'
      srv.editors['kitten'].must_equal Editserver::Kitten
    end
  end

  describe :register_editors do
    before { @srv = Editserver.new }

    it 'should not mutate passed options Hash' do
      opts = { 'default' => 'cat', 'cat' => 'cat --regular' }
      @srv.register_editors opts
      opts['default'].must_equal 'cat'
    end

    it 'should set the default key' do
      @srv.register_editors 'default' => 'vim'
      @srv.editors['default'].must_equal 'vim'
    end

    it 'should create new subclasses of Editor, and place them in the @editors Hash' do
      @srv.register_editors 'kitty_kitty' => 'cat --here-kitty-kitty'
      Editserver.constants.must_include :KittyKitty
      @srv.editors['kitty_kitty'].must_equal Editserver::KittyKitty
    end

    it 'should split editor command like a Bourne shell' do
      @srv.register_editors 'adorable_cat' => 'cat --with "really long whiskers"'
      Editserver::AdorableCat.instance_variable_get(:@command).must_equal ['/bin/cat', '--with', 'really long whiskers']
    end

    it 'should alter @editors and return the value of @editors' do
      @srv.register_editors('ugly_cat' => 'cat --manginess=100').must_equal @srv.editors
    end
  end

  describe :editor do
    before { @srv = Editserver.new }

    it 'should take a single string argument' do
      @srv.method(:editor).arity.must_equal 1
      lambda { @srv.editor %w[/foo] }.must_raise TypeError
    end

    it 'should raise RoutingError if no handler found for path' do
      lambda { @srv.editor '/escape-meta-alt-control-shift' }.must_raise Editserver::RoutingError
    end

    it 'should return an existing subclass of Editor when a handler exists' do
      @srv.editor('/vim').ancestors.must_include Editserver::Editor
      @srv.register_editors 'kitty_cat' => 'cat --with-nick'
      @srv.editor('/kitty_cat').ancestors.must_include Editserver::Editor
    end

    it 'should return a default handler for / if defined' do
      lambda { @srv.editor '/' }.must_raise Editserver::RoutingError
      @srv.register_editors 'default' => 'emacs'
      @srv.editor('/').must_equal Editserver::Emacs
    end
  end

  describe :call do
    before do
      bin      = File.expand_path '../test-editor', __FILE__
      @srv     = Editserver.new 'default' => 'test-editor', 'test-editor' => bin
      @env_for = Rack::MockRequest.method :env_for
      @uri     = 'http://127.0.0.1:9999'

      # don't clutter test output
      $stderr.reopen '/dev/null'
    end

    after { $stderr.reopen STDERR }

    it 'should take a rack env hash' do
      @srv.method(:call).arity.must_equal 1
      lambda { @srv.call :foo => 'bar' }.must_raise NoMethodError
    end

    it 'should return a rack array' do
      res = @srv.call @env_for.call(@uri)
      res.must_be_kind_of Array
      res.length.must_equal 3
      res[0].must_be_kind_of Fixnum
      res[1].must_be_kind_of Hash
      res[2].must_be_kind_of Rack::Response
    end

    it 'should spawn the specified editor and return an edited string' do
      @srv.call(@env_for.call @uri)[2].body.join.must_match /test-editor\z/
      @srv.call(@env_for.call @uri + '/?text=foobarbaz')[2].body.join.must_match /\Afoobarbaz.*test-editor\z/m
    end
  end
end
