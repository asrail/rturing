require "gtk2"
require "turing/machine"
require "interface/factory"
require "mathn"

class Buttons < Gtk::HBox
  attr_accessor :botoes,:first,:prev,:stop,:play,:step,:last
  def initialize(window)
    super()
     [[Gtk::Stock::GOTO_FIRST, "_Reiniciar"],
       [Gtk::Stock::GO_BACK, "_Voltar"],
       [Gtk::Stock::STOP, "_Parar"],
       [Gtk::Stock::YES, "E_xecutar"],
       [Gtk::Stock::GO_FORWARD, "Ava_nçar"],
       [Gtk::Stock::GOTO_LAST, "Últi_mo"]
     ].each { |id, label|
      Gtk::Stock.add(id, label)
     }
     buttons = [
       [:first, Gtk::Stock::GOTO_FIRST], 
       [:prev, Gtk::Stock::GO_BACK], 
       [:stop, Gtk::Stock::STOP], 
       [:play, Gtk::Stock::YES], 
       [:step, Gtk::Stock::GO_FORWARD],
       [:last, Gtk::Stock::GOTO_LAST]]

    buttons.each {|but, icon|
      sbut = but.to_s
      if icon
        send(sbut+"=", Gtk::Button.new(icon,true))
      else
        send(sbut+"=", Gtk::Button.new(sbut.capitalize,true))
      end
      send(sbut).signal_connect("clicked") {
        window.send(sbut)
      }
      pack_start(send(sbut),false,false,1)
    }
  end
end

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
      rb.signal_connect(signal) {
        response.call(rb,kind[rb].to_s)
      }
    }
  end
end

class Menus < Gtk::MenuBar
  attr_accessor :menus
  def initialize(window)
    super()
    @window = window
    Gtk::Stock.add(Gtk::Stock::EDIT, "_Fita")
    Gtk::Stock.add(Gtk::Stock::EXECUTE, "_Máquina")
    Gtk::Stock.add(Gtk::Stock::CONVERT, "_Timeout")
    kind = RadioList.new("Tipo _de máquina")
    kind.append("_Gturing",:gturing)
    kind.append("_Wiesbaden",:wiesbaden)
    kind.add_signal("toggled") {|item,kind|
      Turing::Machine.default_kind = kind if item.active?
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


class ExistemErros < Gtk::MessageDialog
  def initialize(window, erros)
    super(window,
          Gtk::MessageDialog::MODAL,
          Gtk::MessageDialog::ERROR,
          Gtk::MessageDialog::BUTTONS_CLOSE,
          "Existem erros na máquina a ser carregada. " +
          "O primeiro fica na linha #{erros[0][0]}, que é " +
          "\"#{erros[0][1]}\". Provavelmente, isso é por um " +
          "desrespeito ao formato, que é:\n" +
          "<estado_atual> <simbolo_lido> <simbolo_escrito> " +
          "<direcao> <novo_estado>\n" +
          "Onde direção é d, e, l, ou r.")
  end
end

class SalvaAntes < Gtk::Dialog
  def initialize(operacao, window)
    super("Deseja #{operacao} sem salvar?",
          window, 
          Gtk::Dialog::MODAL, 
          [Gtk::Stock::CANCEL, 
            Gtk::Dialog::RESPONSE_CANCEL],
          [Gtk::Stock::NO, 
            Gtk::Dialog::RESPONSE_NO],
          [Gtk::Stock::YES, 
            Gtk::Dialog::RESPONSE_YES])
    message = "Existem alterações não gravadas na máquina.\n" +
      "Deseja salvar antes de #{operacao}?"
    hbox = Gtk::HBox.new
    hbox.add(Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, 
                              Gtk::IconSize::DIALOG))
    hbox.add(Gtk::Label.new(message))
    hbox.show_all
    self.vbox.add(hbox)
    self.show_all
  end
end


class JanelaPrincipal < Gtk::Window
  attr_accessor :ag
  attr_reader :timeout

  def initialize
    super
    self.title = "RTuring"
    @saved = true
    signal_connect("delete_event") {
      false
    }
    signal_connect("delete-event") {
      quit
    }
    self.border_width = 1
    self.window_position = POS_CENTER
    @timeout = 100
    @ag = Gtk::AccelGroup.new
    self.add_accel_group(@ag)
    @maquina = Turing::Machine.new
    @maquina.setup("Bem vindo ao rturing.")
    linhas = Gtk::VBox.new(false,0)
    @menu = Menus.new(self)
    linhas.pack_start(@menu,false,false,0)
    @fita = Gtk::Label.new
    @fita.set_alignment(0,0)
    @cabecote = Gtk::Label.new
    @cabecote.set_alignment(0,0)
    @status = Gtk::Statusbar.new
    @status.push(@status.get_context_id("estado"), "nunca aparece")
    self.update_labels
    exec_field = Gtk::VBox.new(false,0)
    exec_field.pack_start(@fita,false,false,0)
    exec_field.pack_start(@cabecote,false,false,0)
    linhas.pack_start(exec_field,false,false,2)
    linhas.pack_start(Gtk::HSeparator.new.set_size_request(500, 2),false,false,2)
    button_line = hcenter(Buttons.new(self))
    linhas.pack_start(button_line,false,true)
    linhas.pack_end(Gtk::VBox.new(false,0).pack_start(@status),false,false)
    add(linhas)
    show_all
  end

  def hcenter(widget)
    line = Gtk::HBox.new(false,0)
    line.pack_start(Gtk::HBox.new)
    line.pack_start(widget,false,false)
    line.pack_start(Gtk::HBox.new)
  end

  def timeout=(timeout)
    @timeout = timeout unless timeout.zero? #to create a dialog informing it
  end

  def quit
    if @saved
      Gtk.main_quit
    else
      deseja_salvar = SalvaAntes.new("sair", self)
      deseja_salvar.run { |response|
        if response == Gtk::Dialog::RESPONSE_YES
          if save_machine
            Gtk.main_quit
          end
        elsif response == Gtk::Dialog::RESPONSE_NO
          Gtk.main_quit
        end
        deseja_salvar.destroy
        show_all
      }
    end
  end

  def play(timeout=@timeout)
    timeout,rev = timeout.polar
    @tid = Gtk::timeout_add(timeout) {
      stop if (rev.zero? && @maquina.halted) || (!rev.zero? && @maquina.machines == [@maquina.machines[0]])
      rev.zero? ? step : prev
    }
  end

  def last
    play(0)
  end

  def prev
    @maquina.unstep if @maquina.halted
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
    @cabecote.set_markup("<span face=\"Courier\">#{"_"*@maquina.machines[-1].pos}^</span>")
    @status.pop(@status.get_context_id("estado"))
    @status.push(@status.get_context_id("estado"), "Estado atual: #{@maquina.state}")
  end

  def set_trans(trans, window, saved=false)
    begin
      tape = @maquina.tape.to_s[1..-1]
      maquina = Turing::Machine.new(trans)
      maquina.setup(tape)
      @maquina = maquina
      @saved = saved
      return true
    rescue Turing::InvalidMachine => m
      dialog = ExistemErros.new(window, m.erros)
      dialog.run {}
      dialog.destroy
      return false
    end
  end

  def open_file
    if not @saved
      deseja_salvar = SalvaAntes.new("abrir outra máquina", self)
      deseja_salvar.run { |response|
        if response == Gtk::Dialog::RESPONSE_YES
          if save_machine
            open_file
          end
        elsif response == Gtk::Dialog::RESPONSE_NO
          @saved = true
          open_file
        end
        deseja_salvar.destroy
      }
    else
      dialog = Gtk::FileChooserDialog.new("Open File",
                                          self,
                                          Gtk::FileChooser::ACTION_OPEN,
                                          nil,
                                          [Gtk::Stock::CANCEL, 
                                            Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::OPEN, 
                                            Gtk::Dialog::RESPONSE_ACCEPT])
      
      runned = dialog.run
      success = false
      if runned == Gtk::Dialog::RESPONSE_ACCEPT
        File.open(dialog.filename) { |file|
          success = set_trans(file.read, dialog, true)
        }
        @maquina.setup ""
      end
      dialog.destroy
      if runned == Gtk::Dialog::RESPONSE_ACCEPT and success
        self.choose_tape
      end
    end
  end

  def save_machine
    dialog = Gtk::FileChooserDialog.new("Salvar Máquina",
                                        self,
                                        Gtk::FileChooser::ACTION_SAVE,
                                        nil,
                                        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                        [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
    
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
    ChooseDialog.new("Selecionar fita",@maquina.tape.to_s[1..-1],"Entre com a fita: #") {|input,dialog|
      @maquina.setup(input.text)
      self.first # não faz sentido editar a fita sem ver o resultado
      self.update_labels
      dialog.destroy
    }
  end

  def choose_timeout
    ChooseDialog.new("Editar timeout",@timeout.to_s,"Entre com tempo desejado:") {|input,dialog|
      self.timeout = input.text.to_i
      dialog.destroy
    }
  end

  def edit_machine
    EditDialog.new("Editar Máquina",@maquina.trans.to_s,"") { |maquina_atual,dialog|
      set_trans(maquina_atual.text, dialog)
      self.first # não faz sentido editar os estados no meio, ainda
      self.update_labels
      dialog.destroy
    }
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
  Gtk::init
  w = JanelaPrincipal.new
  Gtk.main
end

if __FILE__ == $0
  main()
end
