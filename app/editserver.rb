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
    else raise EditError, "No handler for #{path}"
    end
  end

  def filepath
    name = case request.env['HTTP_ORIGIN']
    when 'chrome-extension://ppoadiihggafnhokfkpphojggcdigllp' # TextAid
      request.params['id'] + ' ' + request.params['url'].gsub(/\W+/, '-') + '.txt'
    else
      'editserver.txt'
    end

    dir  = '/tmp/editserver'
    file = "#{dir}/#{name}"

    FileUtils.mkdir_p dir             # create dir
    FileUtils.chmod 0700, dir         # ensure permissions even if already exists
    File.open(file, 'a', 0600).close  # create file
    FileUtils.chmod 0600, file        # ensure permissions

    file
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
