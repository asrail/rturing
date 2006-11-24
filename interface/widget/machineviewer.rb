require 'gtk2'

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
    @sons = []
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
    @sons.each { |s|
      s.update_labels
    }
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
    new_sons = []
    @sons.each {|s|
      s.unstep
      if s.machine.on_start?
        self.remove(s)
      else
        new_sons.push(s)
      end
    }
    @sons = new_sons
    update_labels
    show_all
    @machine.unstep if @machine.halted
    @machine.unstep
  end

  def halted
    halt = false
    @sons.each {|s|
      halt |= s.halted
    }
    halt |= @machine.halted
    return halt
  end
  
  def tape_both_sides(tape_both)
    @machine.first.pos = tape_both ? 0 : 1
    if tape_both
      @machine.tape.tape.shift if @machine.tape.tape[0] == '#'
    else
      @machine.tape.tape.unshift('#') if @machine.tape.tape[0] != '#'
      update_labels
    end
  end
  
  def setup(tape)
    @machine.first
    @sons.each {|s|
      self.remove(s)
    }
    @sons = []
    @machine.setup(tape)
  end
  
  def first
    @machine.current = @machine.first
  end
  
  def go_to_start
    first
  end
  
  def clear
    self.each {|child|
      self.remove(child)
    }
  end

  def step
    @sons.each { |s|
      s.step
      Gtk.main_iteration
    }
    @machine.step.each { |machine|
      a = MachineViewer.new(machine, self)
      Gtk.main_iteration
      @sons.push(a)
      self.pack_start(a)
    }
    update_labels
    show_all
  end
  
  def light_step
    @sons.each {|s|
      s.light_step
      Gtk.main_iteration
    }
    @machine.light_step.each { |machine|
      a = MachineViewer.new(machine, self)
      Gtk.main_iteration
      @sons.push(a)
      self.pack_start(a)
    }
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
