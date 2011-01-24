require 'editserver/editor'

class EditServer
  class Mate < Editor
    define_editor 'mate', '-w'
  end
end
