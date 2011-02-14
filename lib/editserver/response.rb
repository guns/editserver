require 'tempfile'
require 'rack/response'

class Editserver
  class Response
    attr_reader :editor, :request, :response, :tempfile

    def initialize editor, request
      @editor   = editor
      @request  = request
      @response = Rack::Response.new
      @tempfile = Tempfile.new filename

      # TODO: Why doesn't tempfile.write work here?
      text = request.params['text']
      File.open(tempfile.path, 'w') { |f| f.write text } if text
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

      name.gsub /[^\w\. ]+/, '-'
    end

    def call
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
  end
end
