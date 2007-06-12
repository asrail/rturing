require 'gtk2'


class RModel < Gtk::TreeStore
  def initialize(trans)
    super(String, String, String, String, String)
    trans.states.each { |estado,s|
      s.each {|simbolo, c|
        linha = append nil
        dados = [estado, simbolo, c.written_symbol, 
               c.direction, c.new_state]
        puts "dados = #{dados}, class = #{dados[1].class}"
        5.times {|i|
          set_value(linha, i, dados[i])
        }
      }
    }
  end
  
  
end

class Editor < Gtk::TreeView
  
  def initialize(trans)
    super(RModel.new(trans))
    @trans = trans
    headers_visible = true
    headers_clickable = false
    rules_hint = true
    reorderable = false
    fixed_height_mode = true
    colunas = ["Estado", "Lido", "Escrito", "Direcao", "Proximo"]
    5.times {|e|
      insert_column(-1, colunas[e], Gtk::CellRendererText.new, {:text => e})
    }
  end
  
end
