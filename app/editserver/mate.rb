require 'editserver/editor'

class EditServer
  class Mate < Editor
    define_editor 'mate', '-w'

    def edit file
      mate file
      File.read file
    end
  end
end
