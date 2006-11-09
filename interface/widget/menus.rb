require "gtk2"
require "interface/widget/radiolist"
require "interface/widget/cmi"

class Menus < Gtk::MenuBar
  attr_accessor :menus, :entries, :actgroup
  def initialize(window)
    super()
    @window = window
    kind = ConfigRadioList.new("Tipo _de máquina",window, "tipo")
    kind.append("_Gturing",:gturing)
    kind.append("_Wiesbaden",:wiesbaden)
    kind.add_signal("toggled") {|item,kind,window|
      if item.active?
        Turing::Machine.default_kind = kind
        window.first
        window.update_labels
        window.edit_machine unless window.validate(kind)
      end
    }
    mboth = ConfigCheckMenuItem.new(:mboth,"Infinita para os dois lados")
    mboth.signal_connect("toggled") {|item,kind|
      Turing::Machine.toggle_both_sides
      window.first
      window.tape_both_sides(item.active?)
      window.update_labels
    }
    light = ConfigCheckMenuItem.new(:light, 
                                    "Modo \"light\" para economizar memória")
    window.light_mode = light.active?
    light.signal_connect("toggled") { |item, kind|
      window.first
      window.light_mode ^= true
      window.botoes.prev.sensitive = !window.light_mode
      window.update_labels
    }
      
    @actgroup = window.actgroup
    proc = Proc.new {|actg, act|
      @window.send(act.name)
    }
    @entries = [
       ["open_file", Gtk::Stock::OPEN, "_Abrir",
        "<control>o", "Carregar uma máquina de um arquivo", proc],
       ["save_machine", Gtk::Stock::SAVE, "_Salvar",
        "<control>s", "Salva a máquina para um arquivo", proc],
       ["choose_tape", Gtk::Stock::EDIT, "_Fita",
        "<control>f", "Permite editar a fita", proc],
       ["edit_machine", Gtk::Stock::EXECUTE, "_Máquina",
        "<control>m", "Permite editar a máquina", proc],
       ["about", Gtk::Stock::ABOUT, "_About",
        "F1", "rTuring...", proc],
       ["quit", Gtk::Stock::QUIT, "Sai_r",
        "<control>q", "Sai do programa", proc],
       ["choose_timeout", Gtk::Stock::CONVERT, "_Timeout",
        "<control>t", "Permite editar o intervalo entre os passos", proc]
     ]
    @actgroup.add_actions(@entries)
    @accgroup = window.ag
    mconfigs = Gtk::MenuItem.new("_Configurar").set_submenu(Gtk::Menu.new.append(kind).append(mboth).append(light))
    edit = menuItem(*["_Editar", ["choose_tape", "edit_machine", "choose_timeout"]])
    file = menuItem(*["_Arquivo", ["open_file", "save_machine", "quit"]])
    about = menuItem(*["Aj_uda", ["about"]])
    append(file)
    append(edit)
    append(mconfigs)
    append(about)
  end

  def menuItem(name,submenu=nil)
    sup_menu = Gtk::MenuItem.new(name)
    if submenu
      menu = Gtk::Menu.new
      menu.accel_group = @window.ag
      submenu.each {|sub|
        act = @actgroup.get_action(sub)
        if !act.nil?
          item = Gtk::ImageMenuItem.new(act.stock_id||act.name)
          acc_name = @entries.find {|e|
            e[0] == act.name
          }[3]
           acc = Gtk::Accelerator.parse(acc_name)
           item.add_accelerator("activate", menu.accel_group, acc[0], acc[1],
                                  Gtk::ACCEL_VISIBLE)
          act.accel_group = @accgroup
          act.connect_proxy(item)
          menu.append(item)
        end
      }
    end
    sup_menu.set_submenu(menu)
    sup_menu
  end

  private :entries, :entries=
end
