$:.unshift File.expand_path('../../lib', __FILE__)

require 'tempfile'
require 'editserver/editor'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'

describe Editserver::Editor do
  before do
    class Editserver
      class CleverCat < Editor
        define_editor 'cat', '--clever'
      end
    end
    @klass = Editserver::CleverCat
  end

  describe :self do
    describe :define_editor do
      it "should populate the new class metaclass's @command" do
        @klass.instance_variable_get(:@command).must_equal %w[/bin/cat --clever]
      end
    end

    describe :@@terminal do
      it "should have a reader and writer for the metaclass's @@terminal" do
        @klass.terminal = nil
        @klass.terminal.must_equal nil
        @klass.terminal = 'xterm -fg white -bg black'
        @klass.terminal.must_equal %w[xterm -fg white -bg black]
      end
    end
  end # self

  describe :terminal do
    it 'should have a reader for @@terminal at the instance level' do
      @klass.terminal = nil
      @klass.new.terminal.must_equal nil
      @klass.terminal = 'urxvt -g 80x24'
      @klass.new.terminal.must_equal %w[urxvt -g 80x24]
    end
  end

  describe :edit do
    before do
      class Editserver
        class TestEditor < Editor
          define_editor File.expand_path('../../test-editor', __FILE__)
        end
      end
      @klass = Editserver::TestEditor
      @file  = Tempfile.new File.basename($0)
    end

    after { @file.close; @file.unlink }

    it 'should write file with error message is editor is not found' do
      class Editserver
        class MysteryPony < Editor
          define_editor 'magic-pony', '--mysterious'
        end
      end

      Editserver::MysteryPony.new.edit @file.path
      @file.read.must_match /not found:/
    end

    it 'should write the passed file' do
      @file.write 'MAGICPONY'
      @file.rewind
      @klass.new.edit @file.path
      @file.read.must_match /\AMAGICPONY.*test-editor\z/m
    end
  end
end
