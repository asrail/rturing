require 'pp'
module Turing #:nodoc
  class MTKind
    attr_accessor :name,:exp,:order,:move

    def initialize(name,exp,order,move)
      @name = name
      @exp = exp
      @order = order
      @move = move
    end

    def dir_to_amount(dir)
      if ['r',move[:r]].include?dir then
        1
      elsif ['l',move[:l]].include?dir then
        -1
      else
        0
      end
    end
  end

  class Rule
    attr_accessor :new_state, :direction, :written_symbol

    def initialize (symb, dir, st)
      @new_state = st
      @direction = dir
      @written_symbol = symb
    end
    
    def to_s
      "#{@written_symbol} #{@direction} #{@new_state}"
    end
  end
  
  class ExecutionEnded < RuntimeError
  end

  class InvalidMachine < StandardError
    attr_accessor :erros
    def initialize(erros)
      super()
      self.erros = erros
    end
  end
  
  class MTMatcher
    attr_accessor :state,:symb_r,:symb_w,:dir,:new_state

    def initialize(md,order)
      self.state,self.symb_r,self.symb_w,self.dir,self.new_state = order.map { |x|
        md[x]
      }
    end
  end

  class MTRegex < Regexp
    def initialize(exp,order=nil)
      if not order.nil?
        if exp.kind_of?Symbol
          @order = order
        else
          @order = [1,2,3,4,5]
        end
      elsif exp.kind_of?MTKind
        @order = exp.order
        exp = exp.exp
      end
      super(exp)
    end
    def match(str)
      md = super(str)
      return nil unless md
      MTMatcher.new(md,@order)
    end
  end

  class TransFunction
    attr_reader :states, :original

    def get(state, symbol)
      return ((@states[state] and 
               @states[state][symbol]) or raise ExecutionEnded)
    end
    
    def set(state, symbol, rule)
      @states[state][symbol] = rule
    end

    def initialize(aut,regex)
      linhas_erradas = []
      n_linha = 0
      @states = {}
      @original = aut
      aut.each_line do |line|
        n_linha += 1
        next if line =~ /^\s*#/
        md = regex.match(line)
        if not md
          linhas_erradas.push([n_linha, line])
          next
        end
        state = md.state.to_i
        symb_r = md.symb_r
        symb_w = md.symb_w
        dir = md.dir
        new_state = md.new_state.to_i
        if !@states[state] then
          @states[state] = Hash.new
        end
        @states[state][symb_r] = Rule.new(symb_w, dir, new_state)
      end
      if linhas_erradas != []
        raise InvalidMachine.new(linhas_erradas)
      end
    end
    
    def to_s
      @original
    end
  end
  
  class MachineState
    attr_accessor :tape, :state, :pos, :trans, :halted, :kind

    def initialize(trans, tape, state, pos, kind, halt=false)
      @trans = trans
      @tape = tape
      @state = state
      @pos = pos
      @kind = kind
      self.halted = halt
    end
    
    def next
      begin
        rule = @trans.get(state, @tape.get(pos))
        new_state = rule.new_state
        new_symbol =  rule.written_symbol
        newpos = kind.dir_to_amount(rule.direction) + pos
        newtape = tape.set_at(pos, new_symbol)
        if newpos < 0
          newpos = 0
          newtape.tape = ["_"] + newtape.tape
        end
        return MachineState.new(trans, newtape, new_state, newpos, kind)
      rescue ExecutionEnded
        return MachineState.new(trans, tape, state, pos, kind, true)
      end
    end
  end
  
  class Tape
    attr_accessor :tape

    def initialize(t)
      @tape = t.split(//)
    end
    
    def get(pos)
      return ((pos >= tape.size) or (pos < 0))? "_" : tape[pos]
    end

    def set_at(pos, val)
      while pos >= tape.size do
        tape.push("_")
      end
      ntape = Array.new(tape)
      ntape[pos] = val
      return Tape.new(ntape.join(""))
    end
    
    def to_s
      return tape.join("")
    end
  end
  
  class Machine
    attr_accessor :trans, :machines, :regex, :kind

    @@gturing = MTKind.new(:gturing,
%r((?x)
  ^\s*(\S+)
   \s*(\S+)
   \s*(\S+)
   \s*(l|r|e|d)
   \s*(\S+)
   (\s*(.*))?$),
       [1,2,3,4,5],
              {:l => 'e',:r => 'd'})

    def self.default_kind
      @@gturing
    end

    def default_kind
      self.default_kind
    end

    def halted
      @machines[-1].halted
    end
    
    def halted=(value)
      @machines[-1].halted = value
    end
    
    def state
      @machines[-1].state
    end

    def self.from_file(filename = nil)
      if filename
        File.open(filename) do |file| 
          Machine.new(file.read)
        end
      else
        Machine.new("")
      end
    end
    
    def initialize(transf="", kind=@@gturing)
      @kind = kind
      self.regex = MTRegex.new(kind.exp,kind.order)
      @trans = TransFunction.new(transf, self.regex)
    end
    
    def setup(tape)
      @machines = [MachineState.new(trans, Tape.new("#" + tape), 0, 1, kind)]
      self.halted = @trans.states.empty?
    end

    def tape
      @machines[0].tape
    end

    def step(i = 1)
      i.times do
        return if halted
        machines.push(machines[-1].next) 
      end
    end
    
    def unstep(i = 1)
      i.times do 
        if machines[1]
          machines.pop 
        end
      end
    end
    
    def tape
      machines[-1].tape.tape
    end

    def print
      estado = @machines[-1]
      fita = estado.tape
      puts fita
      puts " "*estado.pos + "^"
    end
   
    def to_s
      @trans.to_s
    end
    
    def process(update = nil)
      while !halted
        step
        send(update) if update
      end
    end
  end
end


def main
  if ARGV.size == 2
    machine = Turing::Machine.new(ARGV[0])
    machine.setup(ARGV[1])
    machine.process(:print)
  end
end

if __FILE__ == $0
  main()
end


