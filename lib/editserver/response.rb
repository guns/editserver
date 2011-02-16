require 'tempfile'
require 'rack/response'

class Editserver
  class Response
    attr_reader :editor, :request, :response

    def initialize editor, request
      @editor   = editor
      @request  = request
      @response = Rack::Response.new
    end

    def call
      tempfile = mktemp
      editor.edit tempfile.path
      response.write File.read(tempfile.path)
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

    def mktemp
      file = Tempfile.new filename

      if text = request.params['text']
        file.write text
        file.rewind
      end

      file
    end

    def filename
      # `id' and `url' sent by TextAid
      name    = 'editserver'
      id, url = request.params.values_at 'id', 'url'

      if id or url
        name << '-' << id  if id
        name << '-' << url if url
      else
        if agent = request.env['HTTP_USER_AGENT']
          name << '-' << agent.split.first
        end
      end

      name.gsub /[^\w\.]+/, '-'
    end
  end
end
