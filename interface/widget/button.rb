require "gtk2"

class Buttons < Gtk::HBox
  attr_accessor :botoes,:first,:prev,:stop,:play,:step,:last
  def initialize(window)
    super()
    @actgroup = window.but_actgroup
    proc = Proc.new {|actg, act|
      window.send(act.name)
    }
    buttons = [
       ["first", Gtk::Stock::GOTO_FIRST, "_Reiniciar", "", "Retorna ao estado inicial", proc], 
       ["prev", Gtk::Stock::GO_BACK, "_Voltar", "", "Retrocede um passo", proc],
       ["stop", Gtk::Stock::STOP, "_Parar", "", "Interrompe a execução", proc], 
       ["play", Gtk::Stock::YES, "E_xecutar", "", "Inicia a execução", proc], 
       ["step", Gtk::Stock::GO_FORWARD, "Ava_nçar", "", "Avança um passo", proc],
       ["last", Gtk::Stock::GOTO_LAST, "Últi_mo", "", "Avança até o último passo ou primeiro loop infinito", proc]]
    @actgroup.add_actions(buttons)
    buttons.each {|but|
      act = @actgroup.get_action(but[0])
      if !act.nil?
        item = Gtk::Button.new(act.stock_id.to_sym||act.name)
        act.accel_group = @accgroup
        act.connect_proxy(item)
        pack_start(item,false,false,1)
      end
    }
  end
end
