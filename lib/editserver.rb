require 'tempfile'
require 'shellwords'
require 'rack'
require 'editserver/terminal/vim'

class Editserver
  class EditError < StandardError; end

  attr_accessor :request, :response, :tempfile, :terminal, :editors

  def initialize options = {}
    opts      = options.dup
    @terminal = opts.delete 'terminal'
    register_editors opts
  end

  # returns Hash of name => EditorClass
  def register_editors opts = {}
    @editors ||= {}

    # `default' is a path to redirect to
    if default = opts.delete('default')
      @editors['default'] = default
    end

    # rest should be editor definitions
    opts.each do |name, cmd|
      klass = pascalize name
      editor, params = cmd.shellsplit.partition.with_index { |w,i| i.zero? }

      self.class.class_eval %Q(                          # e.g. mate: mate -w
        class #{klass} < Editor                          # class Mate < Editor
          define_editor #{editor[0].inspect}, *#{params} #   define_editor 'mate', *['-w']
        end                                              # end
      )

      @editors[name] = self.class.const_get klass.to_sym
    end

    @editors
  end

  # returns Editserver handler based on path
  def editor
    path = request.path_info[%r(\A([/\w-]+)), 1]

    if klass = editors[path[/\/(.*)/, 1]]
      klass
    elsif path == '/'
      klass = editors[editors['default']]
    end

    raise EditError, "No handler for #{path}" if klass.nil?
    klass
  end

  def filename
    # `id' and `url' sent by TextAid
    name    = 'editserver'
    id, url = request.params.values_at 'id', 'url'

    if id or url
      name << '-' << id  if id
      name << '-' << url if url
    else
      name << '-' << request.env['HTTP_USER_AGENT'].split.first
    end
  end

  def filepath
    return tempfile.path if tempfile

    @tempfile = Tempfile.new sanitize(filename)
    text      = request.params['text']

    # TODO: Why doesn't tempfile.write work here?
    File.open(tempfile.path, 'w') { |f| f.write text } if text
    tempfile.path
  end

  def call env
    @request  = Rack::Request.new env
    @response = Rack::Response.new

    editor.new.edit filepath

    response.write File.read(filepath)
    response.finish
  rescue EditError => e
    response.write e.to_s
    response.status = 500 # server error
    response.finish
  ensure
    if tempfile
      tempfile.close
      tempfile.unlink
    end
  end

  private

  def sanitize str
    str.gsub /[^\w\. ]+/, '-'
  end

  def pascalize str
    str.capitalize.gsub(/_+(.)/) { |m| m[1].upcase }
  end
end
