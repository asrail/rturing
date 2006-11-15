require "gtk2"
require "turing/machine"
require "interface/factory"
require "interface/widget/machineviewer"
require "mathn"

class MainWindow < Gtk::Window
  attr_accessor :ag, :actgroup, :light_mode, :file, :but_actgroup
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
    @but_actgroup = Gtk::ActionGroup.new("GUIButtons")
    begin
      @machine = Turing::Machine.from_file(m)
    rescue
      @machine = Turing::Machine.new
    end
    @machine.setup((t or ""))
    linhas = Gtk::VBox.new(false,0)
    @menu = Menus.new(self)
    linhas.pack_start(@menu,false,false,0)
    @mview = MachineViewer.new(@machine)
    @mview.update_labels
    #exec_field = Gtk::VBox.new(false,0)
    #exec_field.pack_start(@fita,false,false,0)
    #exec_field.pack_start(@cabecote,false,false,0)
    scroll = Gtk::ScrolledWindow.new
    scroll.hscrollbar_policy = Gtk::POLICY_AUTOMATIC
    scroll.vscrollbar_policy = Gtk::POLICY_AUTOMATIC
    scroll.add_with_viewport(@mview)
    linhas.pack_start(scroll,false,false,2)
    linhas.pack_start(Gtk::HSeparator.new.set_size_request(500, 2),false,false,2)
    @botoes =  Buttons.new(self)
    button_line = hcenter(@botoes)
    linhas.pack_start(button_line,false,true)
    add(linhas)
    @actgroup.get_action("save_machine").sensitive = false
    @but_actgroup.get_action("prev").sensitive = false
    @but_actgroup.get_action("stop").sensitive = false
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
      stop if (rev.zero? && @machine.halted) || (!rev.zero? && @machine.machines == [@machine.machines[0]])
      rev.zero? ? m_step : m_prev
      update_labels
    }
  end

  def play(timeout=@timeout)
    @but_actgroup.get_action("stop").sensitive = true
    @but_actgroup.get_action("play").sensitive = false
    @but_actgroup.get_action("last").sensitive = false
    @but_actgroup.get_action("step").sensitive = false
    @but_actgroup.get_action("prev").sensitive = false
    m_play(timeout)
    @but_actgroup.get_action("prev").sensitive = !self.light_mode && @machine.machines.size > 1
  end

  def last
    @but_actgroup.get_action("last").sensitive = false
    @but_actgroup.get_action("step").sensitive = false
    @but_actgroup.get_action("prev").sensitive = false
    m_play(0)
  end

  def m_prev
    @machine.unstep if @machine.halted
    @machine.unstep
  end

  def prev
    m_prev
    @but_actgroup.get_action("prev").sensitive = !self.light_mode && @machine.machines.size > 1
    @but_actgroup.get_action("last").sensitive = true
    @but_actgroup.get_action("step").sensitive = true
    update_labels
  end

  def m_first
    @machine.machines = [@machine.machines[0]]
    @machine.machines[0].trans = @machine.trans
  end

  def first
    m_first
    @but_actgroup.get_action("prev").sensitive = false
    @but_actgroup.get_action("step").sensitive = true
    @but_actgroup.get_action("last").sensitive = true
    update_labels
  end

  def m_stop
    Gtk::timeout_remove(@tid) if @tid
    @tid = nil
  end

  def stop
    @but_actgroup.get_action("stop").sensitive = false
    @but_actgroup.get_action("play").sensitive = true
    m_stop
    @but_actgroup.get_action("last").sensitive = !@machine.halted
    @but_actgroup.get_action("step").sensitive = !@machine.halted
    @but_actgroup.get_action("prev").sensitive = !self.light_mode && @machine.machines.size > 1
  end

  def m_step
    if light_mode
      @machine.light_step
    else
      @machine.step
    end
  end

  def step
    @but_actgroup.get_action("last").sensitive = false
    @but_actgroup.get_action("step").sensitive = false
    m_step
    @but_actgroup.get_action("prev").sensitive = !self.light_mode && @machine.machines.size > 1
    @but_actgroup.get_action("last").sensitive = !@machine.halted
    @but_actgroup.get_action("step").sensitive = !@machine.halted
    update_labels
  end

  def tape_both_sides(tape_both)
    @machine.machines[0].pos = tape_both ? 0 : 1
    if tape_both
      @machine.tape.tape.shift if @machine.tape.tape[0] == '#'
    else
      @machine.tape.tape.unshift('#') if @machine.tape.tape[0] != '#'
      update_labels
    end
  end

  def validate(kind)
    begin
      t = Turing::TransFunction.new(@machine.trans.to_s,kind)
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
      both = Turing::Machine.both_sides
      tape = @machine.tape.to_s[(both ? 0 : 1)..-1]
      machine = Turing::Machine.new(trans)
      machine.setup(tape)
      @machine = machine
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
        @machine.setup ""
      end
      dialog.destroy
      if runned == Gtk::Dialog::RESPONSE_ACCEPT and success
        self.choose_tape
      end
    end
  end

  def write_machine(filename)
      File.open(filename, "w") { |file|
        file.write(@machine.trans.to_s)
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
    ChooseDialog.new("Selecionar fita",@machine.tape.to_s[(both ? 0 : 1)..-1],
                     "Entre com a fita: #{'#' unless both}", nil) {|input,dialog|
      @machine.setup(input.text)
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
    EditDialog.new("Editar Máquina",@machine.trans.to_s,"") { |machine_atual,dialog|
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
