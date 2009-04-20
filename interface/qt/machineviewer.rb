require 'Qt4'
$KCODE='utf8'

class MachineViewer < Qt::VBoxLayout
  attr_accessor :machine, :fita, :cabecote, :estado, :chars
  def initialize(machine, parent)
    super()
    @parent = parent
    @machine = machine
    @fita = Qt::Label.new
#    @fita.ellipsize = Pango::Layout::ELLIPSIZE_NONE
    @cabecote = Qt::Label.new
    @halted = Qt::Label.new
    @icon = Qt::Icon.new("images/32/media-record.png")
#    @event = Qt::StatusBar.new(parent)
#    @event.setObjectName('statusbar')
##    parent.setStatusBar(@event)
#    @event.addWidget(@halted)
#    @tips = Gtk::Tooltips.new
#    @tips.set_tip(@event, "A máquina não foi carregada.", "")
#    @tips.enable
    @estado = Qt::Label.new
    @chars = Qt::Label.new
    @this_m = Qt::VBoxLayout.new
    @this_m.addWidget(@fita)
    @this_m.addWidget(@cabecote)
    hb = Qt::HBoxLayout.new
    hb.addWidget(@halted)
    hb.addWidget(@estado)
    hb.addWidget(@chars)
    @this_m.addLayout(hb)
    self.addLayout(@this_m)
    update_labels
  end

  def update_labels
    @fita.setText(tr("<span face=\"Courier\">#{@machine.tape.to_s}</span>"))
    @cabecote.setText(tr("<span face=\"Courier\">#{"_"*@machine.current.pos}^</span>"))
    if @machine.halted 
      @halted.pixmap = @icon.pixmap(22, 22, Qt::Icon::Disabled)
#      @tips.set_tip(@event, "A máquina está parada " + 
#                    "(ie, a função de transição não está definida).", "")
    else
    @halted.pixmap = @icon.pixmap(22, 22)
#      @halted = "No" #.set(Gtk::Stock::NO, Gtk::IconSize::MENU)
#      @tips.set_tip(@event, "A máquina ainda não chegou ao fim.", "")
    end
    @estado.setText(tr("Estado atual: %s." % @machine.state, "Number of actual state"))
    i = 0
    @machine.tape.tape.each { |char|
      if not ((char == " ") or (char == "#") or (char == "_"))
        i += 1
      end
    }

    if i > 0
      @chars.setText(tr("%s caracteres não nulos." % i, "Number of characters on tape"))
    else
      @chars.setText(tr("Nenhum caracter não-nulo."))
    end
  end

  def unstep
    update_labels
    @machine.unstep if @machine.halted
    @machine.unstep
    if @machine.on_start?
      self.first
    end
  end

  def halted
    @machine.halted
  end
  
  def tape_both_sides(tape_both)
    @machine.toggle_both_sides
  end
  
  def setup(tape)
    @machine.first
    @machine.setup(tape)
  end
  
  def first
    @machine.current = @machine.first
    @machine.tape = Turing::Tape.new(@machine.first_tape.to_s)
  end
  
  def go_to_start
    first
  end
  
  def step
    @machine.step
    update_labels
  end
  
  def light_step
    @machine.light_step
    update_labels
  end

  def trans
    @machine.trans
  end

  def tape
    @machine.tape
  end
  
  def on_start?
    @machine.on_start?
  end
  
end
