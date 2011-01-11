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

class EditServer
  class VimError < StandardError; end

  attr_accessor :request, :response

  def vim *args
    @@vim ||= begin
      bin = %x(which vim).chomp
      raise VimError, 'Vim not found!' unless File.executable? bin
      bin
    end

    cmd = [@@vim, *args]
    out = %x(#{cmd.shelljoin} 2>&1).chomp

    if $?.exitstatus.zero?
      out
    else
      raise VimError, out
    end
  end

  def server_available?
    vim('--serverlist').split("\n").map { |l| l.strip.downcase }.include? 'vimserver'
  end

  # FIXME: files should be temporary; client should send extant text
  def edit name
    if server_available?
      file = "/tmp/vimpreview/#{name}"
      FileUtils.mkdir_p File.dirname(file), :mode => 0700
      File.open(file, 'a', 0600).close
      vim '--servername', 'vimserver', '--remote-tab-wait', file
      File.read file
    else
      raise VimError, 'No Vim server available!'
    end
  end

  def filename
    case request.env['HTTP_ORIGIN']
    when 'chrome-extension://ppoadiihggafnhokfkpphojggcdigllp' # TextAid
      request.params['id'] + ' ' + request.params['url'].gsub(/\W+/, '-') + '.txt'
    else
      'editserver.txt'
    end
  end

  def call env
    self.request  = Rack::Request.new env
    self.response = Rack::Response.new

    response.write edit(filename)
    response.finish
  rescue VimError => e
    response.write e.to_s
    response.finish
  end
end
