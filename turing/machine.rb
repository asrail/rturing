require 'turing/model'

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
      if move[:r].include?dir then
        1
      elsif move[:l].include?dir then
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
    def initialize(exp)
      @order = exp.order
      exp = exp.exp
      super(exp)
    end

    def match(str)
      md = super(str)
      return nil unless md
      MTMatcher.new(md,@order)
    end
  end

  class TransFunction
    attr_reader :states, :original, :inicial

    def get(state, symbol)
      return ((@states[state] and 
               @states[state][symbol]) or raise ExecutionEnded)
    end
    
    def set(state, symbol, rule)
      @states[state][symbol] = rule
    end

    def initialize(aut,regex)
      if regex.kind_of?String
        regex = Model.send(regex)
      end
      if regex.kind_of?Array
        regex = MTRegex.new(MTKind.new(*regex))
      end
      @inicial = nil
      linhas_erradas = []
      n_linha = 0
      @states = {}
      @original = aut
      aut.each_line do |line|
        n_linha += 1
        next if line =~ /^\s*(#|$)/
        md = regex.match(line)
        if not md
          linhas_erradas.push([n_linha, line])
          next
        end
        state = md.state
        if !@inicial
          @inicial = state
        end
        symb_r = md.symb_r
        symb_w = md.symb_w
        dir = md.dir
        new_state = md.new_state
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
    attr_accessor :tape, :state, :pos, :trans, :halted, :kind, :prev

    def initialize(trans, tape, state, pos, kind, prev, halt=false)
      @trans = trans
      @tape = tape
      @state = state
      @pos = pos
      @kind = kind
      @prev = prev
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
          if Machine.both_sides
            newpos = 0
            newtape.tape = ["_"] + newtape.tape
          else 
            raise ExecutionEnded
          end
        end
        return MachineState.new(trans, newtape, new_state, newpos, kind, self)
      rescue ExecutionEnded
        return MachineState.new(trans, tape, state, pos, kind, self, true)
      end
    end
  end
  
  class Tape
    attr_accessor :tape

    def initialize(t)
      @tape = t.gsub(/ /,'_').split(//)
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
      tape = @tape.join("")
      tape.gsub(/_/,' ')
    end
  end
  

  class Machine
    attr_accessor :trans, :first, :current, :regex, :kind, :both

    @@both_sides = true
    @@kind = Model::gturing
    
    def initialize(transf="", both_sides=@@both_sides, kind_m=@@kind)
      @first = @current = nil
      @kind = MTKind.new(*kind_m)
      @both = both_sides
      self.regex = MTRegex.new(kind)
      @trans = TransFunction.new(transf, self.regex)
    end

    def self.default_kind
      @@kind
    end

    def default_kind
      self.class.default_kind
    end

    def default_kind=(kind)
      self.class.default_kind=(kind)
    end

    def self.default_kind=(kind)
      if /(?i)gturing/ =~ kind
        @@kind = Model::gturing
      elsif /(?i)wiesbaden/ =~ kind
        @@kind = Model::wiesbaden
      end
    end

    def self.both_sides
      @@both_sides
    end

    def self.toggle_both_sides
      @@both_sides = !self.both_sides
    end

    def self.both_sides=(both_sides)
        @@both_sides = both_sides
    end

    def halted
      @current.halted
    end
    
    def halted=(value)
      @current.halted = value
    end
    
    def state
      @current.state
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
    

    def setup(tape,both=@@both_sides)
      @first = @current = MachineState.new(trans, Tape.new("#{'#' unless both}#{tape}"), 
                                           trans.inicial, both ? 0 : 1, kind, nil)
      self.halted = @trans.states.empty?
    end


    def step
      return if halted
      @current = @current.next
    end
    
    def on_start?
      first == current
    end
    
    def light_step
      return if halted
      @current = @current.next
      @current.prev = @first
    end
    
    def unstep
      if @current != @first
        @current = @current.prev
      end
    end
    
    def tape
      @current.tape
    end

    def print
      fita = current.tape
      puts fita
      puts " "*current.pos + "^"
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
    machine = Turing::Machine.from_file(ARGV[0])
    machine.setup(ARGV[1])
    machine.process(:print)
  end
end

if __FILE__ == $0
  main()
end


