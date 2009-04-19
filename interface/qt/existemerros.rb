require 'Qt4'

class ExistemErros
  def initialize(parent, erros)
    @parent = parent
    @erros = erros
  end

  def run
    message = Qt::Object::tr("Existem erros na máquina a ser carregada. " +
                 "O primeiro fica na linha #{erros[0][0]}, que é " +
                 "\"#{erros[0][1]}\". Provavelmente, isso é por um " +
                 "desrespeito ao formato, que é:\n" +
                 "<estado_atual> <simbolo_lido> <simbolo_escrito> " +
                 "<direcao> <novo_estado>\n" +
                 "Onde direção é d, e, l, ou r.")
    Qt::MessageBox::error(parent,
                          Qt::Object::tr("Erro"),
                          message)
  end
end
