class ExistemErros < Gtk::MessageDialog
  def initialize(window, erros)
    super(window,
          Gtk::MessageDialog::MODAL,
          Gtk::MessageDialog::ERROR,
          Gtk::MessageDialog::BUTTONS_CLOSE,
          "Existem erros na máquina a ser carregada. " +
          "O primeiro fica na linha #{erros[0][0]}, que é " +
          "\"#{erros[0][1]}\". Provavelmente, isso é por um " +
          "desrespeito ao formato, que é:\n" +
          "<estado_atual> <simbolo_lido> <simbolo_escrito> " +
          "<direcao> <novo_estado>\n" +
          "Onde direção é d, e, l, ou r.")
  end
end
