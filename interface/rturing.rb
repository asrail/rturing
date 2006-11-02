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
  attr_accessor :menus, :file, :help, :about
  def initialize(window)
    super()
    @window = window
    submenus = [
      [:file, [:open, :quit]], 
      [:edit, [:tape]], 
      [:help, [:about]]]
    mnemonics = {
      :open => [Gdk::Keyval::GDK_O, Gdk::Window::CONTROL_MASK],
      :tape  => [Gdk::Keyval::GDK_E, Gdk::Window::CONTROL_MASK],
      :about => [Gdk::Keyval::GDK_F1, 0],
      :quit => [Gdk::Keyval::GDK_Q,Gdk::Window::CONTROL_MASK]
    }
    submenus.each {|item,submenu|
      menuItem(item,mnemonics,submenu)
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

  def menuItem(nome,mnemonics,submenu=nil)
    nome = Gtk::MenuItem.new("_" + nome.to_s.capitalize)
    if submenu
      menu = Gtk::Menu.new
      submenu.each {|sub|
        item = Gtk::MenuItem.new("_" + sub.to_s.capitalize)
        item.signal_connect("activate") {
          self.send(sub)
        }
        if mnemonics.key?sub
          item.add_accelerator("activate", @window.ag, mnemonics[sub][0], mnemonics[sub][1],
                               Gtk::ACCEL_VISIBLE)
        end
        menu.append(item)
      }
    end
    nome.set_submenu(menu)
    append(nome)
    nome.show
  end
end

class JanelaPrincipal < Gtk::Window
  attr_accessor :ag

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

    @ag = Gtk::AccelGroup.new
    self.add_accel_group(@ag)

    @maquina = Turing::Machine.new
    @maquina.setup("Bem vindo ao rturing.")
    
    @linhas = Gtk::VBox.new
    @menu = Menus.new(self)
    @linhas.pack_start(@menu,false,false,0)
    @fita = Gtk::Label.new
    @fita.set_alignment(0,0)
    @cabecote = Gtk::Label.new
    @cabecote.set_alignment(0,0)
    @status = Gtk::Statusbar.new
    @status.push(@status.get_context_id("estado"), "nunca aparece")
    self.update_labels
    @linhas.pack_start(@fita)
    @linhas.pack_start(@cabecote)
    @botoes = Buttons.new(self)
    @linhas.pack_start(@botoes)
    @linhas.pack_start(@status)
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
    @status.pop(@status.get_context_id("estado"))
    @status.push(@status.get_context_id("estado"), "Estado atual: #{@maquina.state}")
  end

  def open_file
    dialog = Gtk::FileChooserDialog.new("Open File",
                                        self,
                                        Gtk::FileChooser::ACTION_OPEN,
                                        nil,
                                        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                        [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    
    runned = dialog.run
    if runned == Gtk::Dialog::RESPONSE_ACCEPT
      @maquina = Turing::Machine.new(dialog.filename)
      @maquina.setup ""
    end
    dialog.destroy
    if runned == Gtk::Dialog::RESPONSE_ACCEPT
      self.choose_tape
    end
  end
  
  def choose_tape
    linha = Gtk::HBox.new
    label = Gtk::Label.new "Enter the tape: #"
    linha.pack_start(label)
    input = Gtk::Entry.new
    input.text = @maquina.tape.to_s[1..-1]
    linha.pack_start(input)
    dialog = Gtk::Dialog.new("Tape Selector",
                             self,
                             Gtk::Dialog::MODAL,
                         
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE])
    input.signal_connect("key_press_event") {|inp, ev|
      if Gdk::Keyval.to_name(ev.keyval) == "Return"
        dialog.signal_emit("response", 0)
      end
    }
    dialog.signal_connect("response") {
      @maquina.setup(input.text)
      self.first # não faz sentido editar a fita sem ver o resultado
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
