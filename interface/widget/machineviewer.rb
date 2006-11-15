require 'gtk2'

class MachineViewer < Gtk::VBox
  attr_accessor :machine, :fita, :cabecote, :halted, :estado, :chars
  def initialize(machine)
    super()
    @machine = machine
    @fita = Gtk::Label.new
    @fita.set_alignment(0,0)
    @fita.selectable = true
    @fita.ellipsize = Pango::Layout::ELLIPSIZE_NONE
    @cabecote = Gtk::Label.new
    @cabecote.set_alignment(0,0)
    @halted = Gtk::Label.new
    @estado = Gtk::Label.new
    @chars = Gtk::Label.new
    self.pack_start(@fita, false, false, 0)
    self.pack_start(@cabecote, false, false, 0)
    hb = Gtk::HBox.new
    hb.pack_start(@halted, false, false, 0)
    hb.pack_start(@estado, false, false, 0)
    hb.pack_start(@chars, false, false, 0)
    self.pack_start(hb, false, false, 0)
    update_labels
  end
  
  def update_labels
    @fita.set_markup("<span face=\"Courier\">#{@machine.tape.to_s}</span>")
    @cabecote.set_markup("<span face=\"Courier\">#{"_"*@machine.machines[-1].pos}^</span>")
    if @machine.halted 
      @halted.set_markup("Parada. ")
    else
      @halted.set_markup("Rodando. ")
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
end
