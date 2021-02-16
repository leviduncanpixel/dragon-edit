require 'app/editor.rb'

def tick args
  $editor ||= Editor.new
  $editor.args = args
  $editor.tick
end
