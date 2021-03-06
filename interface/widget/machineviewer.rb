require 'gtk2'
require 'interface/widget/editor.rb'

class MachineViewer < Gtk::VBox
  attr_accessor :machine, :fita, :cabecote, :estado, :chars
  def initialize(machine, parent)
    super()
    @parent = parent
    @machine = machine
    @fita = Gtk::Label.new
    @fita.set_alignment(0,0)
    @fita.selectable = true
    @fita.ellipsize = Pango::Layout::ELLIPSIZE_NONE
    @cabecote = Gtk::Label.new
    @cabecote.set_alignment(0,0)
    @halted = Gtk::Image.new(Gtk::Stock::YES, Gtk::IconSize::MENU)
    @event = Gtk::EventBox.new
    @event.add(@halted)
    @tips = Gtk::Tooltips.new
    @tips.set_tip(@event, "A máquina não foi carregada.", "")
    @tips.enable
    @estado = Gtk::Label.new
    @chars = Gtk::Label.new
    @this_m = Gtk::VBox.new
    @this_m.pack_start(@fita, false, false, 0)
    @this_m.pack_start(@cabecote, false, false, 0)
    hb = Gtk::HBox.new
    hb.pack_start(@event, false, false, 0)
    hb.pack_start(@estado, false, false, 0)
    hb.pack_start(@chars, false, false, 0)
    @this_m.pack_start(hb, false, false, 0)
    self.pack_start(@this_m)
    update_labels
  end
  
  def update_labels
    @fita.set_markup("<span face=\"Courier\">#{@machine.tape.to_s}</span>")
    @cabecote.set_markup("<span face=\"Courier\">#{"_"*@machine.current.pos}^</span>")
    if @machine.halted 
      @halted.set(Gtk::Stock::YES, Gtk::IconSize::MENU)
      @tips.set_tip(@event, "A máquina está parada " + 
                    "(ie, a função de transição não está definida).", "")
    else
      @halted.set(Gtk::Stock::NO, Gtk::IconSize::MENU)
      @tips.set_tip(@event, "A máquina ainda não chegou ao fim.", "")
    end
    @estado.set_markup("Estado atual: #{@machine.state}. ")
    i = 0
    @machine.tape.tape.each { |char|
      if not ((char == " ") or (char == "#") or (char == "_"))
        i += 1
      end
    }
    if i > 1
      @chars.set_markup("#{i} caracteres não nulos.")
    elsif i == 1
      @chars.set_markup("1 caractere não nulo.")
    else
      @chars.set_markup("Nenhum caracter não-nulo.")
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
