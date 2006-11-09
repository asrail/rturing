require "gtk2"

class Buttons < Gtk::HBox
  attr_accessor :botoes,:first,:prev,:stop,:play,:step,:last
  def initialize(window)
    super()
     [[Gtk::Stock::GOTO_FIRST, "_Reiniciar"],
       [Gtk::Stock::GO_BACK, "_Voltar"],
       [Gtk::Stock::STOP, "_Parar"],
       [Gtk::Stock::YES, "E_xecutar"],
       [Gtk::Stock::GO_FORWARD, "Ava_nçar"],
       [Gtk::Stock::GOTO_LAST, "Últi_mo"]
     ].each { |id, label|
      Gtk::Stock.add(id, label)
     }
     buttons = [
       [:first, Gtk::Stock::GOTO_FIRST, true], 
       [:prev, Gtk::Stock::GO_BACK, !window.light_mode], 
       [:stop, Gtk::Stock::STOP, true], 
       [:play, Gtk::Stock::YES, true], 
       [:step, Gtk::Stock::GO_FORWARD, true],
       [:last, Gtk::Stock::GOTO_LAST, true]]

    buttons.each {|but, icon, sensitive|
      sbut = but.to_s
      if icon
        botao = Gtk::Button.new(icon,true)
      else
        botao = Gtk::Button.new(sbut.capitalize,true)
      end
      botao.sensitive = sensitive
      send(sbut+"=",botao)
      send(sbut).signal_connect("clicked") {
        window.send(sbut)
      }
      pack_start(send(sbut),false,false,1)
    }
  end
end
