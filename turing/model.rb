module Model
  def self.gturing
    [:gturing,
%r((?x)
  ^\s*(\S+)
   \s*(\S+)
   \s*(\S+)
   \s*(l|r|e|d)
   \s*(\S+)
   (\s*(.*))?$
), [1,2,3,4,5], {:l => ['e','l'],:r => ['d','r']}]
  end

  def self.wiesbaden 
    [:wiesbaden,
%r((?x)
  ^\s*((?:\w|\d)+)
   ,?\s*((?:\w|\d|[-+\/!@%^&=.()$#*_])+)
   ,?\s*((?:\w|\d)+)
   ,?\s*((?:\w|\d|[-+\/!@%^&=.()$#*_])+)
   ,?\s*(<|>)$
), [1,2,4,5,3], {:l => ['<'], :r => ['>']}]
  end
end
