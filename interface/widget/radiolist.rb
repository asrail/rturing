require "gtk2"

class RadioList < Gtk::MenuItem
  attr_accessor :kind
  def initialize(name)
    @menu = Gtk::Menu.new
    @radio = nil
    @kind = {}
    super(name)
    set_submenu(@menu)
  end

  def append(item,symb)
    if @radio.nil?
      @radio = Gtk::RadioMenuItem.new(item)
      radio = @radio
    else
      radio = Gtk::RadioMenuItem.new(@radio,item)
    end
    kind[radio] = symb
    @menu.append(radio)
  end

  def add_signal(signal,&response)
    self.submenu.children.each {|rb|
      rb.signal_connect(signal) { |window,event|
        response.call(rb,kind[rb].to_s)
      }
    }
  end
end
