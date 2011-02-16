$:.unshift File.expand_path('../../lib', __FILE__)

require 'rack/mock'
require 'editserver/editor'
require 'editserver/response'
require 'minitest/pride' if $stdout.tty?
require 'minitest/autorun'

describe Editserver::Response do
  before do
    class Editserver
      class TestEditor < Editor
        define_editor File.expand_path('../../test-editor', __FILE__)
      end
    end

    @editor = Editserver::TestEditor.new
    @uri    = 'http://127.0.0.1:9999'
    @req    = lambda do |uri|
      Rack::Request.new Rack::MockRequest.env_for(uri)
    end
  end

  describe :initialize do
    it 'should take two arguments' do
      lambda { Editserver::Response.new }.must_raise ArgumentError
      lambda { Editserver::Response.new @editor }.must_raise ArgumentError
      lambda { Editserver::Response.new @editor, @req.call(@uri); raise RuntimeError }.must_raise RuntimeError
    end

    # implicitly tests attr readers as well
    it 'should set public internal state' do
      req = @req.call @uri
      res = Editserver::Response.new @editor, req
      res.editor.must_equal @editor
      res.request.must_equal req
      res.response.must_be_kind_of Rack::Response
    end
  end

  describe :call do
    it 'should modify the body of the response' do
      res = Editserver::Response.new @editor, @req.call(@uri)
      res.call[2].body.join.must_match /test-editor\z/
    end

    it 'should prepend contents of text param to response body if present' do
      res = Editserver::Response.new @editor, @req.call(@uri + '/?text=SUGARPLUM')
      res.call[2].body.join.must_match /\ASUGARPLUM.*test-editor\z/m
    end
  end
end
