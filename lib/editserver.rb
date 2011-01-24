#           __      __
#          /\ \  __/\ \__
#     __   \_\ \/\_\ \ ,_\   ____     __   _ __   __  __     __   _ __
#   /'__`\ /'_` \/\ \ \ \/  /',__\  /'__`\/\`'__\/\ \/\ \  /'__`\/\`'__\
#  /\  __//\ \L\ \ \ \ \ \_/\__, `\/\  __/\ \ \/ \ \ \_/ |/\  __/\ \ \/
#  \ \____\ \___,_\ \_\ \__\/\____/\ \____\\ \_\  \ \___/ \ \____\\ \_\
#   \/____/\/__,_ /\/_/\/__/\/___/  \/____/ \/_/   \/__/   \/____/ \/_/
#
#                                           guns <sung@metablu.com>

require 'tempfile'
require 'editserver/vim'
require 'editserver/mate'

class Editserver
  class EditError < StandardError; end

  VERSION = '0.0.3'

  attr_accessor :request, :response, :tempfile

  # returns Editserver handler based on path
  def editor
    case path = request.path_info[%r(\A/([\w-]+?)\b), 1]
    when 'vim'  then Editserver::Vim
    when 'mate' then Editserver::Mate
    when nil    then Editserver::Vim  # TODO: should be a config option
    else
      raise EditError, "No handler for #{path}"
    end
  end

  def filename
    # `id' and `url' sent by TextAid
    name = 'editserver'
    id   = request.params['id']
    url  = request.params['url']

    if id or url
      name << '-' << id  if id
      name << '-' << url if url
    else
      name << '-' << request.env['HTTP_USER_AGENT'][/\A(\S+)?/, 1]
    end
  end

  def filepath
    return tempfile.path if tempfile

    self.tempfile = Tempfile.new sanitize(filename)
    text          = request.params['text']

    # TODO: Why doesn't tempfile.write work here?
    File.open(tempfile.path, 'w') { |f| f.write text } if text
    tempfile.path
  end

  def sanitize str
    str.gsub /[^\w\. ]+/, '-'
  end

  def call env
    self.request  = Rack::Request.new env
    self.response = Rack::Response.new

    editor.new.edit(filepath)

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
end
