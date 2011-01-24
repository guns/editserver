require 'editserver/editor'

class Editserver
  class Mate < Editor
    define_editor 'mate', '-w'
  end
end
