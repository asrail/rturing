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
    attr_reader :states, :original, :initial

    def get(state, symbol)
      return ((@states[state] and 
               @states[state][symbol]) or [])
    end
    
    def set(state, symbol, rule)
      @states[state][symbol] = rule
    end

    def initialize(aut,regex)
      if regex.kind_of?String
        regex = Model.send(regex)
      elsif regex.kind_of?Array
        regex = MTRegex.new(MTKind.new(*regex))
      end
      @initial = nil
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
        if !@initial
          @initial = state
        end
        symb_r = md.symb_r
        symb_w = md.symb_w
        dir = md.dir
        new_state = md.new_state
        if !@states[state] then
          @states[state] = Hash.new
        end
        if !@states[state][symb_r]
          @states[state][symb_r] = []
        end
        @states[state][symb_r].push(Rule.new(symb_w, dir, new_state))
      end
      if linhas_erradas != []
        raise InvalidMachine.new(linhas_erradas)
      end
    end
    
    def to_s
      @original
    end
  end
  
  class Delta
    attr_accessor :symb_removed, :symb_written, :pos, :kind, :rule
    def initialize(tape, pos, rule, kind, both_sides)
      @symb_removed = tape.get(pos)
      @symb_written = rule.written_symbol
      @pos = pos
      @rule = rule
      @kind = kind
      @both = both_sides
    end
    
    def apply(tape)
      tape.set_at(pos, symb_written)
      if @both && (kind.dir_to_amount(rule.direction) + pos) < 0 # hehe
        tape.grow_left('_')
      end
    end
    
    def unapply(tape)
      if @both && (kind.dir_to_amount(rule.direction) + pos) < 0 # hehe
        tape.shrink
      end
      tape.set_at(pos, symb_removed)
    end
  end
  
  class MachineState
    attr_accessor :tape, :state, :pos, :trans, :halted, :kind, :prev, :delta
    attr_reader :both

    def initialize(trans, tape, state, pos, kind, prev, both_sides, delta=nil, halt=false)
      @trans = trans
      @state = state
      @pos = pos
      @delta = delta
      @kind = kind
      @prev = prev
      @both = both_sides
      self.halted = halt
    end

    def calculate_from_rule(this_rule, tape)
      if !this_rule
        return MachineState.new(trans, tape, state, pos, kind, self, both, nil, true)
      end
      new_state = this_rule.new_state
      delta = Delta.new(tape, pos, this_rule, kind, both)
      newpos = kind.dir_to_amount(this_rule.direction) + pos
      if delta
        delta.apply(tape)
      else
        return calculate_from_rule(nil, tape)
      end
      if newpos < 0 
        if both                 # hehe
          newpos = 0
        else
          return calculate_from_rule(nil, tape)
        end
      end
      return MachineState.new(trans, tape, new_state, newpos, kind, self, both, delta)
    end
    
    def next(tape)
      rules = @trans.get(state, tape.get(pos)).reverse
      this_rule = rules.pop()
      new_tape = Tape.new(tape.to_s) if rules != [] # isso faz uma diferença
                                                    # absurda no tempo de execução.
                                                    # o test_stress sai de 1.8 pra uns
                                                    # 30 segundos se eu tirar o if.
                                                    # Não-determinismo é pior do que
                                                    # eu pensava
      this_next = calculate_from_rule(this_rule, tape)
      machines = []
      rules.each { |r|
        tape = Tape.new(new_tape.to_s)
        s = calculate_from_rule(r, tape)
        machines.push(Machine.from_machinestate(trans, nil, s, tape, both, kind))
      }
      return this_next, machines
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
      tape[pos] = val
    end
    
    def grow_left(char)
      @tape = [char] + @tape
    end

    def shrink
      @tape = @tape[1..-1]
    end
    
    def to_s
      tape = @tape.join("")
      tape.gsub(/_/,' ')
    end
  end
  

  class Machine
    attr_accessor :trans, :first, :current, :regex, :kind, :both, :tape, :first_tape

    @@kind = Model::gturing
    
    def initialize(transf="", both_sides=nil, kind_m=nil)
      @first = @current = nil
      kind_m = Machine.default_kind_for(kind_m) if kind_m.kind_of?String
      if kind_m.kind_of?MTKind
        @kind = kind_m
      else
        @kind = MTKind.new(*(kind_m or @@kind))
      end
      @both = both_sides
      self.regex = MTRegex.new(kind)
      @trans = TransFunction.new(transf, self.regex)
    end

    def self.from_file(filename=nil, kind_str=nil, both_sides=nil)
      if filename
        File.open(filename) do |file| 
          Machine.new(file.read, both_sides, kind_str)
        end
      else
        Machine.new("", both_sides, kind_m)
      end
    end    

    def setup(tape, both=nil)
      @both = both unless both.nil?
      @tape = Tape.new("#{'#' unless @both}#{tape}")
      @first_tape = Tape.new("#{'#' unless @both}#{tape}")
      @first = MachineState.new(trans, @tape, trans.initial, @both ? 0 : 1, kind, nil, @both)
      @current = @first
      self.halted = @trans.states.empty?
    end
    
    def self.from_machinestate(transf, first, current, tape, both, kind)
      m = Machine.new("", both, kind)
      m.trans = transf
      m.first = first
      m.current = current
      m.current.prev = m.first
      m.tape = tape
      m
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
      new_kind = self.default_kind_for(kind)
      @@kind = new_kind unless new_kind.nil?
    end

    def self.default_kind_for(kind)
      if /(?i)gturing/ =~ kind
        Model::gturing
      elsif /(?i)wiesbaden/ =~ kind
        Model::wiesbaden
      end
    end

    def toggle_both_sides
      @both = !@both
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

    def step
      return if halted
      @current, machines = @current.next(tape)
      return machines
    end
    
    def on_start?
      first == current
    end
    
    def light_step
      return if halted
      machines = step
      machines.each { |m|
        m.current.prev = m.first
      }
      @current.prev = @first
      machines
    end
    
    def unstep
      if @current != @first && @current
        @current.delta.unapply(@tape) if @current.delta
        @current = @current.prev
      end
    end
    
    def print
      fita = @current.tape
      puts fita
      puts " "*@current.pos + "^"
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


