require 'Qt4'
require 'turing/machine'
require 'mathn'
require 'salvaantes'
require 'existemerros'
$KCODE='utf8'

class Qt::Action
  ##XXXasrail
  attr_accessor :name
end

class MainWindow < Qt::MainWindow
  attr_accessor :light_mode, :file, :both_sides, :actions
  attr_reader :timeout, :both_sides, :mview
  slots :first, :prev, :stop, :play, :step, :last, :quit, :open_file, :save_machine, :save_machine_as, :choose_tape, :edit_machine, :choose_timeout, :about

  def initialize(m, t, parent = nil)
    super()
    self.windowTitle = tr("gRats")
    self.light_mode = false
    Turing::Machine.default_kind = "gturing"
    self.both_sides = false #Config::client["/apps/rturing/mboth"]
    @saved = true
    @timeout = 100
    aux_actions = {}
    @actions = {}
    begin
      machine = Turing::Machine.from_file(m, Turing::Machine.default_kind, self.both_sides)
    rescue
      machine = Turing::Machine.new("", self.both_sides, Turing::Machine.default_kind)
    end
    machine.setup((t or ""))
    @mview = MachineViewer.new(machine, self)
    @mview.update_labels
    vp = Qt::VBoxLayout.new()
    vp.addLayout(mview)
    toolbar = Qt::ToolBar.new(self)

    aux_actions[:commands] = [
       [:first, "images/32/go-first.png", "&Reiniciar", "", "Retorna ao estado inicial"], 
       [:prev, "images/32/go-previous.png", "&Voltar", "", "Retrocede um passo"],
       [:stop, "images/32/process-stop.png", "&Parar", "", "Interrompe a execução"], 
       [:play, "images/32/media-playback-start.png", "E&xecutar", "Ctrl+r", "Inicia a execução"], 
       [:step, "images/32/go-next.png", "Ava&nçar", "", "Avança um passo"],
       [:last, "images/32/go-last.png", "Últi&mo", "", "Avança até o último passo ou primeiro loop infinito"]
    ]

    aux_actions[:file] = [
       [:open_file, "images/32/document-open.png", "&Abrir",
        "Ctrl+o", "Carregar uma máquina de um arquivo"],
       [:save_machine, "images/32/document-save.png", "&Salvar",
        "Ctrl+s", "Salva a máquina para um arquivo"],
       [:save_machine_as, "images/32/document-save-as.png", "Salvar &como",
        "Ctrl+Shift+s", "Salva a máquina para um novo arquivo"],
       [:quit, "images/32/system-log-out.png", "Sai&r",
        "Ctrl+q", "Sai do programa"]
    ]

    aux_actions[:edit] = [
       [:choose_tape, nil, "&Fita",
        "Ctrl+f", "Permite editar a fita"],
       [:edit_machine, "images/32/emblem-system.png", "&Máquina",
        "Ctrl+m", "Permite editar a máquina"],
       [:choose_timeout, nil, "&Timeout",
        "Ctrl+t", "Permite editar o intervalo entre os passos"]
     ]

     aux_actions[:about] = [
        [:about, nil, "&Sobre",
        "F1", "rTuring..."]
     ]

    aux_actions.each {|group, actions|      
      @actions[group] = actions.map {|but|
        act = Qt::Action.new(self)
        act.text = but[2]
        act.icon = Qt::Icon.new(but[1]) if but[1]
        act.shortcut = but[3] if but[3]
        act.statusTip = but[4]
        act.name = but[0]
        connect(act, SIGNAL(:triggered), self, SLOT(but[0]))
        act
      }
    }

    @menubar = Qt::MenuBar.new(self)
    @menubar.objectName = "menubar"

    aux_menus = [[:file, "&Arquivo"],
             [:edit, "&Editar"],
             [:commands, "&Comandos"],
             [:about, "Aj&uda"]]

    @menus = aux_menus.map {|group, name|
      menu = Qt::Menu.new(@menubar)
      menu.objectName = "menu" + group.to_s
      menu.title = name
      @menubar.addAction(menu.menuAction())
      @actions[group].each {|act|
        menu.addAction(act)
      }
      menu
    }

    @actions[:commands].each {|act|
      toolbar.addAction(act)
    }
    setMenuBar(@menubar)
    toolbar.tool_button_style = Qt::ToolButtonTextBesideIcon ##XXXasrail: preferencia...
    addToolBar(toolbar)
    central = Qt::Widget.new(self)
    central.setLayout(vp)
    setCentralWidget(central)
    Qt::MetaObject.connectSlotsByName(self)
    check_buts
  end

  def timeout=(timeout)
    @timeout = timeout unless timeout.zero? #to create a dialog informing it
  end

  def quit
    if @saved
      emit close()
    else
      deseja_salvar = SalvaAntes.new(tr("sair"), self)
      deseja_salvar.run { |response|
        if response == Qt::MessageBox::Yes
          if save_machine
            emit close()
          end
        elsif response == Qt::MessageBox::No
          emit close()
        end
      }
    end
  end

  def m_play(timeout)
    timeout,rev = timeout.polar
#    @tid = Gtk::timeout_add(timeout) {
#      stop if ((rev.zero? && @mview.halted) || 
#               (!rev.zero? && @mview.on_start?))
#      rev.zero? ? m_step : m_prev
#      update_labels
#    }
  end

  def turn_but_act(act,st)
    ##XXXasrail: requer Qt::Action.name (não padrão)
    @actions[:commands].find {|action| action.name == act}.enabled = st
  end

  def check_buts
    turn_but_act(:stop, @playing)
    turn_but_act(:play, !@playing && !@mview.halted)
    turn_but_act(:last, !@playing && !@mview.halted)
    turn_but_act(:step, !@playing && !@mview.halted)
    turn_but_act(:prev, !@playing && !self.light_mode && !@mview.on_start?)
    turn_but_act(:first, !@playing && !@mview.on_start?)
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
#    Gtk::timeout_remove(@tid) if @tid
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
    # else
    #   dialog = Gtk::FileChooserDialog.new("Open File",
    #                                       self,
    #                                       Gtk::FileChooser::ACTION_OPEN,
    #                                       nil,
    #                                       [Gtk::Stock::CANCEL, 
    #                                         Gtk::Dialog::RESPONSE_CANCEL],
    #                                       [Gtk::Stock::OPEN, 
    #                                         Gtk::Dialog::RESPONSE_ACCEPT])
      
    #   runned = dialog.run
    #   success = false
    #   if runned == Gtk::Dialog::RESPONSE_ACCEPT
    #     File.open(dialog.filename) { |file|
    #       success = set_trans(file.read, dialog, true)
    #     }
    #     @mview.setup ""
    #     self.file = dialog.filename
    #   end
    #   dialog.destroy
    #   if runned == Gtk::Dialog::RESPONSE_ACCEPT and success
    #     self.choose_tape
    #   end
    end
  end

  def write_machine(filename)
      File.open(filename, "w") { |file|
        file.write(@mview.trans.to_s)
      }
      @saved = true
#      @actgroup.get_action("save_machine").sensitive = false
  end

  def save_machine
    if self.file.nil?
      save_machine_as
    else
      write_machine(self.file)
    end
  end

  def save_machine_as
    # dialog = Gtk::FileChooserDialog.new("Salvar Máquina",
    #                                     self,
    #                                     Gtk::FileChooser::ACTION_SAVE,
    #                                     nil,
    #                                     [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
    #                                     [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
    
    # runned = dialog.run
    # if runned == Gtk::Dialog::RESPONSE_ACCEPT
    #   self.file = dialog.filename
    #   write_machine(self.file)
    # end
    # dialog.destroy
    # return runned == Gtk::Dialog::RESPONSE_ACCEPT
  end

  def choose_tape
    both = self.both_sides
    # ChooseDialog.new("Selecionar fita",@mview.tape.to_s[(both ? 0 : 1)..-1],
    #                  "Entre com a fita: #{'#' unless both}", nil) {|input,dialog|
    #   @mview.setup(input.text)
    #   self.first # não faz sentido editar a fita sem ver o resultado
    #   self.update_labels
    #   dialog.destroy
    # }
  end

  def choose_timeout
    # ChooseDialog.new("Editar timeout",@timeout.to_s,"Entre com tempo desejado:","timeout") {|input,dialog|
    #   self.timeout = input.text.to_i
    #   dialog.destroy
    # }
  end

  def edit_machine
    # EditDialog.new("Editar Máquina",@mview.trans.to_s,"") { |machine_atual,dialog|
    #   set_trans(machine_atual.text, dialog)
    #   self.first # não faz sentido editar os estados no meio, ainda
    #   self.update_labels
    #   dialog.destroy
    # }
  end

  def about
    message = "gRats\nUm interpretador de máquinas de turing " +
      "feito por Alexandre Passos, Antonio Terceiro e " +
      "Caio Tiago Oliveira."
    # about = Gtk::MessageDialog.new(@window, 
    #                                Gtk::MessageDialog::MODAL, 
    #                                Gtk::MessageDialog::INFO, 
    #                                Gtk::MessageDialog::BUTTONS_CLOSE,
    #                                message)
    # about.run
    # about.destroy
  end


end

