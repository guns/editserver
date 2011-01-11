#           __      __
#          /\ \  __/\ \__
#     __   \_\ \/\_\ \ ,_\   ____     __   _ __   __  __     __   _ __
#   /'__`\ /'_` \/\ \ \ \/  /',__\  /'__`\/\`'__\/\ \/\ \  /'__`\/\`'__\
#  /\  __//\ \L\ \ \ \ \ \_/\__, `\/\  __/\ \ \/ \ \ \_/ |/\  __/\ \ \/
#  \ \____\ \___,_\ \_\ \__\/\____/\ \____\\ \_\  \ \___/ \ \____\\ \_\
#   \/____/\/__,_ /\/_/\/__/\/___/  \/____/ \/_/   \/__/   \/____/ \/_/
#
#                                           guns <sung@metablu.com>

require 'fileutils'
require 'shellwords'
require 'editserver/vim'
require 'editserver/mate'

class EditServer
  class EditError < StandardError; end

  attr_accessor :request, :response

  # returns EditServer handler based on path
  def editor
    case path = request.path_info[%r(\A/([\w-]+?)\b), 1]
    when 'vim'  then EditServer::Vim
    when 'mate' then EditServer::Mate
    when nil
      if EditServer::Vim.new.server_available?
        EditServer::Vim
      else
        EditServer::Mate
      end
    else
      raise EditError, "No handler for #{path}"
    end
  end

  def filepath
    # `id' and `url' sent by TextAid
    name = if (id = request.params['id']) and (url = request.params['url'])
      "#{id}-#{url}.txt"
    else
      request.env['HTTP_USER_AGENT'][/\A(\S+)?/, 1]
    end

    text = request.params['text']

    dir  = '/tmp/editserver'
    file = "#{dir}/#{sanitize name}"

    FileUtils.mkdir_p dir
    FileUtils.chmod 0700, dir
    if text
      File.open(file, 'w', 0600) { |f| f.write text }
    else
      File.open(file, 'a', 0600).close
    end
    FileUtils.chmod 0600, file

    file
  end

  def sanitize str
    str.gsub /[^\w\.]+/, '-'
  end

  def call env
    self.request  = Rack::Request.new env
    self.response = Rack::Response.new

    response.write editor.new.edit(filepath)
    response.finish
  rescue EditError => e
    response.write e.to_s
    response.finish
  end
end
