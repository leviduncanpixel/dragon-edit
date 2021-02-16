class Editor
  attr_gtk

  attr_accessor :content, :nlhdl

  def initialize
    @crsrp = 0
    @init = false
    @ftc = {r:230,g:230,b:230,a:255}
    @content = ''
    @fts = 0
    @nlhdl = nil
  end

  def init
    outputs.static_solids << {
      x:0,y:0,w:1280,h:720,r:0,g:0,b:0,a:255
    }
    w, _ = gtk.calcstringbox '[0] |', @fts, 'font.ttf'

    outputs.static_solids << {
      x:0,y:0,w:w,h:720,r:0x23,g:0x23,b:0x46,a:0xff,tag: :lnbar
    }

    @init = true
  end

  def render
    lines = @content.wrapped_lines(120 - (@fts * 5))
    lines == [] ? lines = [''] : nil
    # @content.end_with? "\n" ? lines[lines.length] = '' : ''
    outputs.labels << lines.map_with_index do |ln, i|
      lnn = "[#{" "*(lines.length.to_s.length-((i+1).to_s.length))}#{i+1}] |"
      w, h = gtk.calcstringbox lnn, @fts, 'font.ttf'
      outputs.static_solids.select do
        |s| s[:tag] == :lnbar
      end[0].w = w
      {
        x: 5,
        y: 720 - (i * h + 1),
        size_enum: @fts,
        alignment_enum: 0,
        text: ("#{lnn} #{ln}").gsub("\t", '    '),
        font: 'font.ttf'
      }.merge(@ftc)
    end
  end

  def get_in
    @crsrp = @crsrp.clamp 0, @content.length

    inputs.text.each {|str|
      @content.insert @crsrp, str
      @crsrp += 1
    }

    inputs.text.clear

    ctrl = inputs.keyboard.key_held.control_left || inputs.keyboard.key_held.meta

    puts ctrl

    if inputs.keyboard.key_down.enter
      @content.insert @crsrp, "\n"
      @crsrp += 1
    elsif inputs.keyboard.key_down.v && ctrl
      clip = $gtk.ffi_misc.getclipboard
      @content.insert @crsrp, clip
      @crsrp += clip.length
    elsif inputs.mouse.wheel && args.inputs.mouse.wheel.y > 0  && ctrl
      puts "#{@fts}::"
      @fts += 1
      puts "#{@fts}::::"
    elsif inputs.keyboard.key_down.s  && ctrl
      $gtk.ffi_file.write 'editor.txt', @content.gsub("\0", '')
    elsif inputs.keyboard.key_down.shift && inputs.keyboard.key_down.r  && ctrl
      $editor = nil
      $gtk.reset
      return
    elsif inputs.keyboard.key_down.home
      @crsrp = 0
    elsif inputs.keyboard.key_down.end
      @crsrp = @content.length
    # elsif inputs.keyboard.key_down.left
    #   if inputs.keyboard.key_down.control
    #     prompt.move_cursor_left_word
    #   else
    #     prompt.move_cursor_left
    #   end
    # elsif inputs.keyboard.key_down.right
    #   if inputs.keyboard.key_down.control
    #     prompt.move_cursor_right_word
    #   else
    #     prompt.move_cursor_right
    #   end
    elsif inputs.keyboard.key_down.backspace
      return if @content.length.zero? || @crsrp.zero?
      @content.slice!(@crsrp-1)
      @crsrp -= 1
    elsif inputs.keyboard.key_down.delete
      return if @content.length.zero? || @crsrp.equal?(@content.length - 1)
      @content.slice!(@crsrp+1)
    elsif inputs.keyboard.key_down.tab
      @content.insert @crsrp, "\t"
      @crsrp += 1
    end



    inputs.keyboard.key_down.clear
    inputs.keyboard.key_up.clear
    inputs.keyboard.key_held.clear
  end

  def tick
    init unless @init
    render
    get_in
  end
end
