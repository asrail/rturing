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
      Config::client["/apps/rturing/#{@key}"] = @value
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
  @@cont = 0

  def initialize(name,window,key)
    @menu = Gtk::Menu.new
    @radio = nil
    @kind = {}
    @key = key
    @window = window
    super(name)
    set_submenu(@menu)
    proc = Proc.new {|actg, act|
      widget = act.proxies[0]
      if widget.active?
        Turing::Machine.default_kind = kind[widget]
        window.first
        window.update_labels
      end
    }
    @entries = [
       ["gturing", nil, "_Gturing", "", "Modo gturing", proc], 
       ["wiesbaden", nil, "_Wiesbaden", "", "Modo wiesbaden", proc]
    ]
    @actgroup = window.actgroup
    @actgroup.add_actions(@entries)
    @accgroup = window.ag
    @entries.each {|ent|
      act = @actgroup.get_action(ent[0])
      if !act.nil?
        self.append(act)
      end
    }
  end

  def append(act)
    if @radio.nil?
      @radio = ConfigRadioMenuItem.new(@key,act.name,act.label)
      radio = @radio
    else
      radio = ConfigRadioMenuItem.new(@key,act.name,act.label,@radio)
    end
    act.accel_group = @accgroup
    act.connect_proxy(radio)
    kind[radio] = act.name
    @menu.append(radio)
  end

  def add_signal(signal,&response)

    self.signal_connect(signal) {
      self.submenu.children.each {|rb|
        response.call(rb,kind[rb].to_s,@window)
      }
    }
  end
end
