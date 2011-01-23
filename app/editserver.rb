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

class EditServer
  class EditError < StandardError; end

  VERSION = '0.0.2'

  attr_accessor :request, :response, :tempfile

  # returns EditServer handler based on path
  def editor
    case path = request.path_info[%r(\A/([\w-]+?)\b), 1]
    when 'vim'  then EditServer::Vim
    when 'mate' then EditServer::Mate
    when nil    then EditServer::Vim  # TODO: should be a config option
    else
      raise EditError, "No handler for #{path}"
    end
  end

  def filename
    # `id' and `url' sent by TextAid
    if (id = request.params['id']) and (url = request.params['url'])
      "editserver-#{id}-#{url}"
    elsif id
      "editserver-#{id}"
    else
      'editserver-' + request.env['HTTP_USER_AGENT'][/\A(\S+)?/, 1]
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

    response.write editor.new.edit(filepath)
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
