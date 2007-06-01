module Model
  def self.gturing
    [:gturing,
%r((?x)
  ^\s*(\S+) (?# estado atual)
   \s*(\S+) (?# s�mbolo lido)
   \s*(\S+) (?# s�mbolo escrito)
   \s*(l|r|e|d) (?# dire��o a ser seguida)
   \s*(((call)\s+"(\S+)"\s+(\S+)) (?# caso a a��o seja uma subm�quina)
   |(\S+))  (?# caso a a��o seja um estado)
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
