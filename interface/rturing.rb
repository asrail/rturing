require "gtk2"

class Buttons < Gtk::HBox
  attr_accessor :botoes
  def initialize
    super
    @prev = Gtk::Button.new "Prev"
    @prev.signal_connect("clicked") {
      puts "prev"
    }
    pack_start(@prev)
    @stop = Gtk::Button.new "stop"
    @stop.signal_connect("clicked") {
      puts "stop"
    }
    pack_start(@stop)
    @play = Gtk::Button.new "Play"
    @play.signal_connect("clicked") {
      puts "play"
    }
    pack_start(@play)
  end
end

class Menus < Gtk::MenuBar
  attr_accessor :menus, :file, :help
  def initialize
    super
    submenus = {:file => [:open, :quit], :help => [:about]}
    [:file,:help].each {|item|
     menuItem(item,submenus[item])
    }
  end

  def menuItem(nome,submenu=nil)
    nome = Gtk::MenuItem.new(nome.to_s.capitalize)
    if submenu
      menu = Gtk::Menu.new
      submenu.each {|sub|
        item = Gtk::MenuItem.new(sub.to_s.capitalize)
        menu.append(item)
      }
    end
    nome.set_submenu(menu)
    append(nome)
    nome.show
  end
end

class JanelaRTuring < Gtk::Window
  def initialize
    super
    @title = "RTuring"
    signal_connect("delete_event") {
      false
    }
    signal_connect("destroy") {
      Gtk.main_quit
    }
    @border_width = 10

    @linhas = Gtk::VBox.new
    @menu = Menus.new
    @linhas.pack_start(@menu,false,false,0)
    @fita = Gtk::Label.new "# 0 1 0 1 0 0"
    @fita.set_alignment(0,0)
    @linhas.pack_start(@fita)
    @cabecote = Gtk::Label.new "    ^"
    @cabecote.set_alignment(0,0)
    @linhas.pack_start(@cabecote)
    @botoes = Buttons.new
    @linhas.pack_start(@botoes)
    add(@linhas)
    show_all
  end
end




def main
  w = JanelaRTuring.new
  Gtk.main
end


if __FILE__ == $0
  main()
end
