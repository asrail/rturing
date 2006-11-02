require "gtk2"
require "turing/machine"

class Buttons < Gtk::HBox
  attr_accessor :botoes,:first,:prev,:stop,:play,:step
  def initialize(window)
    super()
    buttons = [[:first,1], [:prev,3], [:stop,0], [:play,0], [:step,1]]
    buttons.each {|but,accel|
      sbut = but.to_s
      send(sbut+"=", Gtk::Button.new(sbut.capitalize.insert(accel,'_'),true))
      send(sbut).signal_connect("clicked") {
        window.send(sbut)
      }
      pack_start(send(sbut))
    }
  end
end

class Menus < Gtk::MenuBar
  attr_accessor :menus, :file, :help
  def initialize(window)
    super()
    @window = window
    submenus = [
      [:file, [:open, :quit]], 
      [:edit, [:tape]], 
      [:help, [:about]]]
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
  
  def tape
    @window.choose_tape
  end

  def menuItem(nome,submenu=nil)
    nome = Gtk::MenuItem.new("_" + nome.to_s.capitalize)
    if submenu
      menu = Gtk::Menu.new
      submenu.each {|sub|
        item = Gtk::MenuItem.new("_" + sub.to_s.capitalize)
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

    self.border_width = 1
    self.window_position = POS_CENTER

    @maquina = Turing::Machine.new
    @maquina.setup("Bem vindo ao rturing.")
    
    @linhas = Gtk::VBox.new
    @menu = Menus.new(self)
    @linhas.pack_start(@menu,false,false,0)
    @fita = Gtk::Label.new
    @fita.set_alignment(0,0)
    @cabecote = Gtk::Label.new
    @cabecote.set_alignment(0,0)
    self.update_labels
    @linhas.pack_start(@fita)
    @linhas.pack_start(@cabecote)
    @botoes = Buttons.new(self)
    @linhas.pack_start(@botoes)
    add(@linhas)
    show_all
  end

  def quit
    Gtk.main_quit
  end

  def play(timeout=50)
    @tid = Gtk::timeout_add(timeout) {
      stop if @maquina.halted
      step
    }
  end

  def prev
    @maquina.unstep
    update_labels
  end

  def first
    @maquina.machines = [@maquina.machines[0]]
    update_labels
  end

  def stop
    Gtk::timeout_remove(@tid) if @tid
    @tid = nil
  end

  def step
    @maquina.step
    update_labels
  end

  def update_labels
    @fita.set_markup("<span face=\"Courier\">#{@maquina.tape.to_s}</span>")
    @cabecote.set_markup("<span face=\"Courier\">#{"_"*@maquina.machines[-1].pos}^</span>") # FIXME
  end

  def open_file
    dialog = Gtk::FileChooserDialog.new("Open File",
                                        self,
                                        Gtk::FileChooser::ACTION_OPEN,
                                        nil,
                                        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                        [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    

    if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
      @maquina = Turing::Machine.new(dialog.filename)
      dialog.destroy
      self.choose_tape
    end
  end
  
  def choose_tape
    linha = Gtk::HBox.new
    label = Gtk::Label.new "Enter the tape: #"
    linha.pack_start(label)
    input = Gtk::Entry.new
    linha.pack_start(input)
    dialog = Gtk::Dialog.new("Tape Selector",
                             self,
                             Gtk::Dialog::MODAL,
                         
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE])
    dialog.signal_connect("response") {
      @maquina.setup(input.text)
      self.update_labels
      dialog.destroy
    }
    dialog.vbox.pack_start(linha)
    dialog.show_all
  end

  def about
    message = "RTuring\nUm interpretador de máquinas de turing " +
      "feito por Alexandre Passos, Antonio Terceiro e " +
      "Caio Tiago Oliveira."
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
