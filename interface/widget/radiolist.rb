require "gtk2"
require "interface/config"

class ConfigRadioMenuItem < Gtk::RadioMenuItem
  attr_accessor :value, :key
  def initialize(key,name,label,group=nil)
    @value = name.to_s
    @key = key
    if group
      super(group,label)
    else
      super(label)
    end
    if Config::client["/apps/rturing/#{@key}"] == @value
      self.active = true
    else
      self.active = false
    end
    signal_connect("activate") {
      Config::client["/apps/rturing/#{@key}"] = @value
    }
  end
end

class ConfigRadioList < Gtk::MenuItem
  attr_accessor :kind, :key
  def initialize(name,window,key)
    @menu = Gtk::Menu.new
    @radio = nil
    @kind = {}
    @key = key
    @window = window
    super(name)
    set_submenu(@menu)
  end

  def append(item,symb)
    
    if @radio.nil?
      @radio = ConfigRadioMenuItem.new(@key,symb,item)
      radio = @radio
    else
      radio = ConfigRadioMenuItem.new(@key,symb,item,@radio)
    end
    kind[radio] = symb
    @menu.append(radio)
  end

  def add_signal(signal,&response)
    self.submenu.children.each {|rb|
      rb.signal_connect(signal) {
        response.call(rb,kind[rb].to_s,@window)
      }
    }
  end
end
