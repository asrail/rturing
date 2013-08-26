# -*- coding: utf-8 -*-
module Model
  def self.gturing
    [:gturing,
%r((?x)
  ^\s*(\S+) (?# estado atual)
   \s*(\S+) (?# símbolo lido)
   \s*(\S+) (?# símbolo escrito)
   \s*(l|r|e|d) (?# direção a ser seguida)
   \s*(((call)\s+"(\S+)"\s+(\S+)) (?# caso a ação seja uma submáquina)
   |(\S+))  (?# caso a ação seja um estado)
   (\s*(.*))?$
), [1,2,3,4,7,8,9,5], {:l => ['e','l'],:r => ['d','r']}]
  end

  def self.wiesbaden 
    [:wiesbaden,
%r((?x)
  ^\s*((?:\w|\d)+)
   ,?\s*((?:\w|\d|[-+\/!@%^&=.()$#*_])+)
   ,?\s*((?:\w|\d)+)
   ,?\s*((?:\w|\d|[-+\/!@%^&=.()$#*_])+)
   ,?\s*(<|>)$
), [1,2,4,5,1,1,1,3], {:l => ['<'], :r => ['>']}]
  end
end
