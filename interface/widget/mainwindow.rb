require "gtk2"
require "turing/machine"
require "interface/factory"
require "mathn"

class MainWindow < Gtk::Window
  attr_accessor :ag, :actgroup, :light_mode, :file
  attr_reader :timeout, :botoes

  def initialize(m, t)
    super()
    self.title = "gRats"
    self.light_mode = Config::client["/apps/rturing/light"]
    Turing::Machine.default_kind = Config::client["/apps/rturing/tipo"]
    Turing::Machine.both_sides = Config::client["/apps/rturing/mboth"]
    @saved = true
    signal_connect("delete-event") {
      quit
    }
    self.border_width = 1
    self.window_position = POS_CENTER
    @timeout = 100
    @ag = Gtk::AccelGroup.new
    self.add_accel_group(@ag)
    @actgroup = Gtk::ActionGroup.new("MainMenu")
    begin
      @maquina = Turing::Machine.from_file(m)
    rescue
      @maquina = Turing::Machine.new
    end
    @maquina.setup((t or ""))
    linhas = Gtk::VBox.new(false,0)
    @menu = Menus.new(self)
    linhas.pack_start(@menu,false,false,0)
    @fita = Gtk::Label.new
    @fita.set_alignment(0,0)
    @fita.selectable = true
    @fita.ellipsize = Pango::Layout::ELLIPSIZE_NONE
    @cabecote = Gtk::Label.new
    @cabecote.set_alignment(0,0)
    @status = Gtk::Statusbar.new
    @status.push(@status.get_context_id("estado"), "nunca aparece")
    self.update_labels
    exec_field = Gtk::VBox.new(false,0)
    exec_field.pack_start(@fita,false,false,0)
    exec_field.pack_start(@cabecote,false,false,0)
    scroll = Gtk::ScrolledWindow.new
    scroll.hscrollbar_policy = Gtk::POLICY_AUTOMATIC
    scroll.vscrollbar_policy = Gtk::POLICY_AUTOMATIC
    scroll.add_with_viewport(exec_field)
    linhas.pack_start(scroll,false,false,2)
    linhas.pack_start(Gtk::HSeparator.new.set_size_request(500, 2),false,false,2)
    @botoes =  Buttons.new(self)
    button_line = hcenter(@botoes)
    linhas.pack_start(button_line,false,true)
    linhas.pack_end(Gtk::VBox.new(false,0).pack_start(@status),false,false)
    add(linhas)
    @actgroup.get_action("save_machine").sensitive = false
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
      stop if (rev.zero? && @maquina.halted) || (!rev.zero? && @maquina.maquinas == [@maquina.maquinas[0]])
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
    @maquina.maquinas = [@maquina.maquinas[0]]
    @maquina.maquinas[0].trans = @maquina.trans
    update_labels
  end

  def stop
    Gtk::timeout_remove(@tid) if @tid
    @tid = nil
  end

  def step
    if light_mode
      @maquina.light_step
    else
      @maquina.step
    end
    update_labels
  end

  def tape_both_sides(tape_both)
    @maquina.maquinas[0].pos = tape_both ? 0 : 1
    if tape_both
      @maquina.tape.tape.shift if @maquina.tape.tape[0] == '#'
    else
      @maquina.tape.tape.unshift('#') if @maquina.tape.tape[0] != '#'
      update_labels
    end
  end

  def validate(kind)
    begin
      t = Turing::TransFunction.new(@maquina.trans.to_s,kind)
      return true
    rescue Turing::InvalidMachine
      value = false
      message = "A máquina de turing digitada não é válida."
      d2 = Gtk::MessageDialog.new(nil,
                                  Gtk::MessageDialog::MODAL,
                                  Gtk::MessageDialog::INFO,
                                  Gtk::MessageDialog::BUTTONS_CLOSE,
                                  message)
      d2.run {}
      d2.destroy
      return false
    end
  end

  def update_labels
    @fita.set_markup("<span face=\"Courier\">#{@maquina.tape.to_s}</span>")
    @cabecote.set_markup("<span face=\"Courier\">#{"_"*@maquina.maquinas[-1].pos}^</span>")
    @status.pop(@status.get_context_id("estado"))
    i = 0
    @maquina.tape.tape.each { |char|
      if not ((char == " ") or (char == "#") or (char == "_"))
        i += 1
      end
    }
    @status.push(@status.get_context_id("estado"), "Estado atual: #{@maquina.state}, " +
                 "#{i} caracteres não-nulos")
    
  end

  def set_trans(trans, window, saved=false)
    begin
      tape = @maquina.tape.to_s[1..-1]
      maquina = Turing::Machine.new(trans)
      maquina.setup(tape)
      @maquina = maquina
      @saved = saved
      @actgroup.get_action("save_machine").sensitive = !saved
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
          @actgroup.get_action("save_machine").sensitive = false
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

  def write_machine(filename)
      File.open(filename, "w") { |file|
        file.write(@maquina.trans.to_s)
      }
      @saved = true
      @actgroup.get_action("save_machine").sensitive = false
  end

  def save_machine
    if self.file.nil?
      save_machine_as
    else
      write_machine(self.file)
    end
  end

  def save_machine_as
    dialog = Gtk::FileChooserDialog.new("Salvar Máquina",
                                        self,
                                        Gtk::FileChooser::ACTION_SAVE,
                                        nil,
                                        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                        [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
    
    runned = dialog.run
    if runned == Gtk::Dialog::RESPONSE_ACCEPT
      self.file = dialog.filename
      write_machine(self.file)
    end
    dialog.destroy
    return runned == Gtk::Dialog::RESPONSE_ACCEPT
  end

  def choose_tape
    both = Turing::Machine.both_sides
    ChooseDialog.new("Selecionar fita",@maquina.tape.to_s[(both ? 0 : 1)..-1],
                     "Entre com a fita: #{'#' unless both}", nil) {|input,dialog|
      @maquina.setup(input.text)
      self.first # não faz sentido editar a fita sem ver o resultado
      self.update_labels
      dialog.destroy
    }
  end

  def choose_timeout
    ChooseDialog.new("Editar timeout",@timeout.to_s,"Entre com tempo desejado:","timeout") {|input,dialog|
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
    message = "gRats\nUm interpretador de máquinas de turing " +
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
