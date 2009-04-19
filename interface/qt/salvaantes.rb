require 'Qt4'

class SalvaAntes
  def initialize(operacao, parent = nil)
    @operacao = operacao
    @parent = parent
  end

  def run
    message = Qt::Object::tr("Existem alterações não gravadas na máquina.\n" +
      "Deseja salvar antes de #{@operacao}?")
    yield Qt::MessageBox::warning(@parent,
                                  Qt::Object::tr("Deseja #{@operacao} sem salvar?"),
                                  message,
                                  Qt::MessageBox::Yes | Qt::MessageBox::Default,
                                  Qt::MessageBox::No,
                                  Qt::MessageBox::Cancel | Qt::MessageBox::Escape);
  end
end
