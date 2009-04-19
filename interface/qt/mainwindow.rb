require 'Qt4'
require 'turing/machine'
require 'mathn'
require 'salvaantes'
require 'existemerros'

class MainWindow < Qt::MainWindow
  attr_accessor :light_mode, :file, :both_sides
  attr_reader :timeout, :both_sides, :mview
  slots :first, :prev, :stop, :play, :step, :last, :quit

  def initialize(m, t, parent = nil)
    super()
    self.windowTitle = tr("gRats")
    self.light_mode = false
    Turing::Machine.default_kind = "gturing"
    self.both_sides = false #Config::client["/apps/rturing/mboth"]
    @saved = false #true
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

    aux_actions = [
       ["first()", "images/32/go-first.png", "&Reiniciar", "", "Retorna ao estado inicial"], 
       ["prev()", "images/32/go-previous.png", "&Voltar", "", "Retrocede um passo"],
       ["stop()", "images/32/process-stop.png", "&Parar", "", "Interrompe a execução"], 
       ["quit()", "images/32/media-playback-start.png", "E&xecutar", "Ctrl+R", "Inicia a execução"], 
       ["step()", "images/32/go-next.png", "Ava&nçar", "", "Avança um passo"],
       ["last()", "images/32/go-last.png", "Últi&mo", "", "Avança até o último passo ou primeiro loop infinito"]]

    @actions = aux_actions.map {|but|
      act = Qt::Action.new(self)
      act.setText(but[2])
      act.setIcon(Qt::Icon.new(but[1]))
      act.setShortcut(but[3]) if but[3]
      act.setStatusTip(but[4])
      connect(act, SIGNAL('triggered()'), self, SLOT(but[0]))
      act
    }
    @actions.each {|act|
      toolbar.addAction(act)
    }
 #   @menubar = Qt::MenuBar.new(self)
 #   @menubar.objectName = "menubar"
 #   @menubar.geometry = Qt::Rect.new(0, 0, 800, 23)
#    @menuFile = Qt::Menu.new(@menubar)
#    @menuFile.objectName = "menuFile"
   # setMenuBar(@menubar)
#    @menubar.addAction(@menuFile.menuAction())
#    @actions.each {|act|
 #     @menuFile.addAction(act)
 #   }
    addToolBar(toolbar)
    central = Qt::Widget.new(self)
    central.setLayout(vp)
    setCentralWidget(central)
    Qt::MetaObject.connectSlotsByName(self)
  end

  def timeout=(timeout)
    @timeout = timeout unless timeout.zero? #to create a dialog informing it
  end

  def quit
    if @saved
      close()
    else
      deseja_salvar = SalvaAntes.new(tr("sair"), self)
      deseja_salvar.run { |response|
        if response == QMessageBox::Yes
          if save_machine
            close()
          end
        elsif response == QMessageBox::Cancel
          close()
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
#    @but_actgroup.get_action(act).sensitive = st
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
      dialog.run
      return false
    end
  end
end

