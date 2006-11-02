require "gtk2"
require "turing/machine"

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
  def initialize(window)
    super()
    @window = window
    submenus = {:file => [:open, :quit], :help => [:about]}
    submenus.each {|item,submenu|
     menuItem(item,submenu)
    }
  end
  
  def open
    @window.open_file
  end

  def quit
    @window.quit
  end
  
  def about
    @window.about
  end

  def menuItem(nome,submenu=nil)
    nome = Gtk::MenuItem.new(nome.to_s.capitalize)
    if submenu
      menu = Gtk::Menu.new
      submenu.each {|sub|
        item = Gtk::MenuItem.new(sub.to_s.capitalize)
        item.signal_connect("activate") {
          self.send(sub)
        }
        menu.append(item)
      }
    end
    nome.set_submenu(menu)
    append(nome)
    nome.show
  end
end

class JanelaPrincipal < Gtk::Window
  def initialize
    super
    @title = "RTuring"
    signal_connect("delete_event") {
      false
    }
    signal_connect("destroy") {
      quit
    }
    @border_width = 10
    @window_position = POS_CENTER

    @maquina = Turing::Machine.new
    @maquina.setup("#Bem vindo ao rturing.")
    
    @linhas = Gtk::VBox.new
    @menu = Menus.new(self)
    @linhas.pack_start(@menu,false,false,0)
    @fita = Gtk::Label.new
    @fita.set_markup("<span face=\"Courier\">#{@maquina.tape.to_s}</span>")
    puts @fita.attributes
    @fita.set_alignment(0,0)
    @linhas.pack_start(@fita)
    @cabecote = Gtk::Label.new
    @cabecote.set_markup("<span face=\"Courier\">_^</span>")
    @cabecote.set_alignment(0,0)
    @linhas.pack_start(@cabecote)
    @botoes = Buttons.new
    @linhas.pack_start(@botoes)
    add(@linhas)
    show_all
    
  end
  def quit
    Gtk.main_quit
  end
  def open_file
    puts "open_file"
  end

  def about
    message = "RTuring\nUm interpretador de máquinas de turing " +
      "feito por Alexandre Passos, Antonio Terceiro e " +
      "Caio Tiago Oliveira de Souza."
    about = Gtk::MessageDialog.new(@window, 
                                   Gtk::MessageDialog::MODAL, 
                                   Gtk::MessageDialog::INFO, 
                                   Gtk::MessageDialog::BUTTONS_CLOSE,
                                   message)
    about.run
    about.destroy
  end
end




def main
  w = JanelaPrincipal.new
  Gtk.main
end


if __FILE__ == $0
  main()
end
