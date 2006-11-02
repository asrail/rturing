require "gtk2"
require "turing/machine"

class Buttons < Gtk::HBox
  attr_accessor :botoes,:first,:prev,:stop,:play,:step
  def initialize(window)
    super()
    [[Gtk::Stock::MEDIA_STOP, "Reiniciar"],
      [Gtk::Stock::MEDIA_PREVIOUS, "Voltar"],
      [Gtk::Stock::MEDIA_PAUSE, "Parar"],
      [Gtk::Stock::MEDIA_PLAY, "Executar"],
      [Gtk::Stock::MEDIA_NEXT, "Avançar"]].each { |id, label|
      
      Gtk::Stock.add(id, label)
    }
    buttons = [
      [:first,1, Gtk::Stock::MEDIA_STOP], 
      [:prev, 3, Gtk::Stock::MEDIA_PREVIOUS], 
      [:stop, 0, Gtk::Stock::MEDIA_PAUSE], 
      [:play, 0, Gtk::Stock::MEDIA_PLAY], 
      [:step, 1, Gtk::Stock::MEDIA_NEXT]]
    buttons.each {|but,accel, icon|
      sbut = but.to_s
      if icon
        send(sbut+"=", Gtk::Button.new(icon,true))
      else
        send(sbut+"=", Gtk::Button.new(sbut.capitalize.insert(accel,'_'),true))
      end
      send(sbut).signal_connect("clicked") {
        window.send(sbut)
      }
      pack_start(send(sbut))
    }
  end
end

class Menus < Gtk::MenuBar
  attr_accessor :menus, :arquivo, :ajuda, :about
  def initialize(window)
    super()
    @window = window
    Gtk::Stock.add(Gtk::Stock::EDIT, "Fita")
    Gtk::Stock.add(Gtk::Stock::EXECUTE, "Máquina")
    submenus = [
      [:arquivo, [:open, :save, :quit]], 
      [:editar, [:tape, :machine]], 
      [:ajuda, [:about]]]
    mnemonics = {
      :open => [Gdk::Keyval::GDK_O, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::OPEN],
      :save => [Gdk::Keyval::GDK_O, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::SAVE],
      :tape  => [Gdk::Keyval::GDK_E, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::EDIT],
      :machine  => [Gdk::Keyval::GDK_E, 
        Gdk::Window::CONTROL_MASK, 
        Gtk::Stock::EXECUTE],
      :about => [Gdk::Keyval::GDK_F1, 
        0,
        Gtk::Stock::ABOUT],
      :quit => [Gdk::Keyval::GDK_Q,
        Gdk::Window::CONTROL_MASK,
        Gtk::Stock::QUIT]
    }
    submenus.each {|item,submenu|
      menuItem(item,mnemonics,submenu)
    }
  end
  

  def menuItem(nome,mnemonics,submenu=nil)
    nome = Gtk::MenuItem.new("_" + nome.to_s.capitalize)
    if submenu
      menu = Gtk::Menu.new
      submenu.each {|sub|
        if mnemonics[sub][2]
          item = Gtk::ImageMenuItem.new(mnemonics[sub][2])
        else
          item = Gtk::MenuItem.new("_" + sub.to_s.capitalize)
        end
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

  def machine
    @window.edit_machine
  end
  
  def save
    @window.save_machine
  end

end

class JanelaPrincipal < Gtk::Window
  attr_accessor :ag

  def initialize
    super
    self.title = "RTuring"
    @saved = true
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
    if @saved
      Gtk.main_quit
    else
      message = "Existem alterações não gravadas na máquina.\n" +
        "Deseja mesmo sair?"
      deseja_salvar = Gtk::MessageDialog.new(@window, 
                                             Gtk::MessageDialog::MODAL, 
                                             Gtk::MessageDialog::QUESTION,
                                             Gtk::MessageDialog::BUTTONS_YES_NO,
                                             message)
      deseja_salvar.run { |response|
        if response == Gtk::Dialog::RESPONSE_YES
            Gtk.main_quit
        else
          save_machine
        end
      }
      deseja_salvar.destroy
    end
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
    @maquina.machines[0].trans = @maquina.trans
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

  def save_machine
    dialog = Gtk::FileChooserDialog.new("Salvar Máquina",
                                        self,
                                        Gtk::FileChooser::ACTION_SAVE,
                                        nil,
                                        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                        [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    
    runned = dialog.run
    if runned == Gtk::Dialog::RESPONSE_ACCEPT
      File.open(dialog.filename, "w") { |file|
        file.write(@maquina.trans.to_s)
      }
      @saved = true
    end
    dialog.destroy
    return runned == Gtk::Dialog::RESPONSE_ACCEPT
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

  def edit_machine
    maquina_atual = Gtk::TextBuffer.new
    maquina_atual.insert_interactive_at_cursor(@maquina.trans.to_s, true)
    textentry = Gtk::TextView.new(maquina_atual)
    dialog = Gtk::Dialog.new("Editar Máquina",
                             self,
                             Gtk::Dialog::MODAL,       
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE])
    dialog.signal_connect("response") {
      @maquina.trans = Turing::TransFunction.new(maquina_atual.text)
      self.first # não faz sentido editar os estados no meio, ainda
      @saved = false
      self.update_labels
      dialog.destroy
    }
    dialog.vbox.pack_start(textentry)
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
