require 'shellwords'
require 'rack'
require 'editserver/response'
require 'editserver/terminal/vim'
require 'editserver/terminal/emacs'

class Editserver
  class EditError < StandardError; end
  class RoutingError < StandardError; end

  GUI_EDITORS = {
    # OS X editors
    'mate'   => 'mate -w',
    'mvim'   => 'mvim --nofork --servername EDITSERVER', # does not return when app must be launched
    'bbedit' => 'bbedit -w'                              # does not open file properly when app is launched
  }.select { |k,v| File.executable? %x(which #{k.shellsplit[0]}).chomp }

  attr_reader :editors

  # TODO: We are playing with global constants here;
  #       this is simple, but we should stop
  def initialize options = {}
    opts            = options.dup
    Editor.terminal = opts.delete 'terminal'

    # seed with terminal-based editors, whose server/client modes are a bit too
    # complicated to configure dynamically
    @editors = {
      'vim'   => Vim,
      'emacs' => Emacs
    }

    register_editors GUI_EDITORS.merge(opts)
  end

  # returns Hash of name => EditorClass
  def register_editors options = {}
    opts = options.dup

    if default = opts.delete('default')
      @editors['default'] = default
    end

    # rest should be editor definitions
    opts.each do |name, cmd|
      klass = pascalize name
      editor, params = cmd.shellsplit.partition.with_index { |w,i| i.zero? }

      self.class.class_eval %Q(                                  # e.g. mate: mate -w
        class #{klass} < Editor                                  # class Mate < Editor
          define_editor #{editor[0].inspect}, *#{params.inspect} #   define_editor 'mate', *['-w']
        end                                                      # end
      )

      @editors[name] = self.class.const_get klass.to_sym
    end

    @editors
  end

  # returns Editserver handler based on path
  def editor path_info
    path = path_info[%r(\A([/\w\.-]+)), 1]

    if klass = editors[path[/\/(.*)/, 1]]
      klass
    elsif path == '/'
      klass = editors[editors['default']]
    end

    raise RoutingError, "No handler for #{path}" if klass.nil?
    klass
  end

  def call env
    request = Rack::Request.new env
    klass   = editor request.path_info
    Response.new(klass.new, request).call
  rescue RoutingError => e
    res = Rack::Response.new
    res.write e.to_s
    res.status = 500
    res.finish
  end

  private

  def pascalize str
    str.capitalize.gsub(/[_-]+(.)/) { |m| m[1].chr.upcase }
  end
end
