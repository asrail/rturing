require "gtk2"

class SalvaAntes < Gtk::Dialog
  def initialize(operacao, window)
    super("Deseja #{operacao} sem salvar?",
          window, 
          Gtk::Dialog::MODAL, 
          [Gtk::Stock::CANCEL, 
            Gtk::Dialog::RESPONSE_CANCEL],
          [Gtk::Stock::NO, 
            Gtk::Dialog::RESPONSE_NO],
          [Gtk::Stock::YES, 
            Gtk::Dialog::RESPONSE_YES])
    message = "Existem alterações não gravadas na máquina.\n" +
      "Deseja salvar antes de #{operacao}?"
    hbox = Gtk::HBox.new
    hbox.add(Gtk::Image.new(Gtk::Stock::DIALOG_QUESTION, 
                              Gtk::IconSize::DIALOG))
    hbox.add(Gtk::Label.new(message))
    hbox.show_all
    self.vbox.add(hbox)
    self.show_all
  end
end
