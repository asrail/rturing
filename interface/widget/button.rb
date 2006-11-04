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
       [:first, Gtk::Stock::GOTO_FIRST], 
       [:prev, Gtk::Stock::GO_BACK], 
       [:stop, Gtk::Stock::STOP], 
       [:play, Gtk::Stock::YES], 
       [:step, Gtk::Stock::GO_FORWARD],
       [:last, Gtk::Stock::GOTO_LAST]]

    buttons.each {|but, icon|
      sbut = but.to_s
      if icon
        send(sbut+"=", Gtk::Button.new(icon,true))
      else
        send(sbut+"=", Gtk::Button.new(sbut.capitalize,true))
      end
      send(sbut).signal_connect("clicked") {
        window.send(sbut)
      }
      pack_start(send(sbut),false,false,1)
    }
  end
end
