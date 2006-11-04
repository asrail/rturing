require "gtk2"

class Menus < Gtk::MenuBar
  attr_accessor :menus
  def initialize(window)
    super()
    @window = window
    Gtk::Stock.add(Gtk::Stock::EDIT, "_Fita")
    Gtk::Stock.add(Gtk::Stock::EXECUTE, "_Máquina")
    Gtk::Stock.add(Gtk::Stock::CONVERT, "_Timeout")
    kind = RadioList.new("Tipo _de máquina",window)
    kind.append("_Gturing",:gturing)
    kind.append("_Wiesbaden",:wiesbaden)
    kind.add_signal("toggled") {|item,kind,window|
      if item.active?
        Turing::Machine.default_kind = kind
        window.first
        window.update_labels
        window.edit_machine # forcing the user to validate it
      end
    }
    submenus = [
      [:arquivo, [:open_file, :save_machine, :quit]], 
      [:editar, [kind, :choose_tape, :edit_machine, :choose_timeout]], 
      [:ajuda, [:about], 2]] #os nomes estao hardcodeados ainda
    mnemonics = {
      :open_file => [Gdk::Keyval::GDK_O, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::OPEN],
      :save_machine => [Gdk::Keyval::GDK_S, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::SAVE],
      :choose_tape  => [Gdk::Keyval::GDK_F, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::EDIT],
      :edit_machine  => [Gdk::Keyval::GDK_M, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::EXECUTE],
      :about => [Gdk::Keyval::GDK_F1, 
        0,
        Gtk::Stock::ABOUT],
      :quit => [Gdk::Keyval::GDK_Q,
        Gdk::Window::CONTROL_MASK,
        Gtk::Stock::QUIT],
      :choose_timeout => [Gdk::Keyval::GDK_T,
        Gdk::Window::CONTROL_MASK,
        Gtk::Stock::CONVERT],
    }
    submenus.each {|item,submenu, accel|
      menuItem(item,mnemonics,submenu,accel)
    }
  end

  def menuItem(name,mnemonics,submenu=nil,accel=nil)
    sup_menu = Gtk::MenuItem.new(name.to_s.capitalize.insert(accel.to_i,'_'))
    if submenu
      menu = Gtk::Menu.new
      submenu.each {|sub|
        item = sub if !sub.kind_of?Symbol
        if sub.kind_of?Symbol
          if mnemonics.key?sub and mnemonics[sub][2]
            item = Gtk::ImageMenuItem.new(mnemonics[sub][2])
          else
            item = Gtk::MenuItem.new("_" + sub.to_s.capitalize)
          end
          item.signal_connect("activate") {
            @window.send(sub)
          }
          if mnemonics.key?sub
            item.add_accelerator("activate", @window.ag, mnemonics[sub][0], mnemonics[sub][1],
                                 Gtk::ACCEL_VISIBLE)
          end
        end
        menu.append(item)
      }
    end
    sup_menu.set_submenu(menu)
    append(sup_menu)
    sup_menu.show
  end
end
