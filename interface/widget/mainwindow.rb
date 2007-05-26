require "gtk2"
require "turing/machine"
require "interface/factory"
require "interface/widget/machineviewer"
require "mathn"

class MainWindow < Gtk::Window
  attr_accessor :ag, :actgroup, :light_mode, :file, :but_actgroup, :both_sides
  attr_reader :timeout, :botoes, :mview

  def toggle_both_sides
    @both_sides = !@both_sides
  end

  def initialize(m, t)
    super()
    self.title = "gRats"
    self.light_mode = false # Config::client["/apps/rturing/light"]
    Turing::Machine.default_kind = "wiesbaden" # Config::client["/apps/rturing/tipo"]
    self.both_sides = Config::client["/apps/rturing/mboth"]
    @saved = true
    signal_connect("delete-event") {
      quit
    }
    self.border_width = 1
    self.window_position = POS_CENTER
    @playing = false
    @timeout = 100
    @ag = Gtk::AccelGroup.new
    self.add_accel_group(@ag)
    @actgroup = Gtk::ActionGroup.new("MainMenu")
    @but_actgroup = Gtk::ActionGroup.new("GUIButtons")
    begin
      machine = Turing::Machine.from_file(m, Turing::Machine.default_kind, self.both_sides)
    rescue
      machine = Turing::Machine.new("", self.both_sides, Turing::Machine.default_kind)
    end
    machine.setup((t or ""))
    linhas = Gtk::VBox.new(false,0)
    @menu = Menus.new(self)
    linhas.pack_start(@menu,false,false,0)
    @mview = MachineViewer.new(machine, self)
    @mview.update_labels
    scroll = Gtk::ScrolledWindow.new
    scroll.hscrollbar_policy = Gtk::POLICY_AUTOMATIC
    scroll.vscrollbar_policy = Gtk::POLICY_AUTOMATIC
    #scroll.add_with_viewport(@mview)
    hadj = Gtk::Adjustment.new(100, 100, 1000, 1, 1, 1)
    vadj = Gtk::Adjustment.new(50, 50, 1000, 1, 1, 1)
    vp = Gtk::Viewport.new(hadj, vadj)
    vp.add(@mview)
    scroll.add(vp)
    linhas.pack_start(scroll,false,false,2)
    linhas.pack_start(Gtk::HSeparator.new.set_size_request(500, 2),false,false,2)
    @botoes =  Buttons.new(self)
    button_line = hcenter(@botoes)
    linhas.pack_start(button_line,false,true)
    add(linhas)
    @actgroup.get_action("save_machine").sensitive = false
    check_buts
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

  def m_play(timeout)
    timeout,rev = timeout.polar
    @tid = Gtk::timeout_add(timeout) {
      stop if ((rev.zero? && @mview.halted) || 
               (!rev.zero? && @mview.on_start?))
      rev.zero? ? m_step : m_prev
      update_labels
    }
  end

  def turn_but_act(act,st)
    @but_actgroup.get_action(act).sensitive = st
  end

  def check_buts
    turn_but_act("stop", @playing)
    turn_but_act("play", !@playing && !@mview.halted)
    turn_but_act("last", !@playing && !@mview.halted)
    turn_but_act("step", !@playing && !@mview.halted)
    turn_but_act("prev", !@playing && !self.light_mode && !@mview.on_start?)
    turn_but_act("first", !@playing && !@mview.on_start?)
  end

  def play(timeout=@timeout)
    @playing = true
    check_buts
    m_play(timeout)
  end

  def last
    check_buts
    m_play(0)
  end

  def m_prev
    @mview.unstep
  end

  def prev
    m_prev
    check_buts
    update_labels
  end

  def m_first
    @mview.go_to_start
  end

  def first
    m_first
    check_buts
    update_labels
  end

  def m_stop
    Gtk::timeout_remove(@tid) if @tid
    @tid = nil
  end

  def stop
    @playing = false
    m_stop
    check_buts
  end

  def m_step
    if light_mode
      @mview.light_step
    else
      @mview.step
    end
  end

  def step
    m_step
    check_buts
    update_labels
  end

  def tape_both_sides(tape_both)
    @mview.tape_both_sides(tape_both)
  end

  def validate(kind)
    begin
      t = Turing::TransFunction.new(@mview.trans.to_s,kind)
      return true
    rescue Turing::InvalidMachine
      return false
    end
  end

  def update_labels
    @mview.update_labels
  end

  def set_trans(trans, window, saved=false)
    begin
      both = self.both_sides
      tape = @mview.tape.to_s[(both ? 0 : 1)..-1]
      machine = Turing::Machine.new(trans, self.both_sides, Turing::Machine.default_kind)
      machine.setup(tape)
      @mview.machine = machine
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
        @mview.setup ""
        self.file = dialog.filename
      end
      dialog.destroy
      if runned == Gtk::Dialog::RESPONSE_ACCEPT and success
        self.choose_tape
      end
    end
  end

  def write_machine(filename)
      File.open(filename, "w") { |file|
        file.write(@mview.trans.to_s)
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
    both = self.both_sides
    ChooseDialog.new("Selecionar fita",@mview.tape.to_s[(both ? 0 : 1)..-1],
                     "Entre com a fita: #{'#' unless both}", nil) {|input,dialog|
      @mview.setup(input.text)
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
    EditDialog.new("Editar Máquina",@mview.trans.to_s,"") { |machine_atual,dialog|
      set_trans(machine_atual.text, dialog)
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
