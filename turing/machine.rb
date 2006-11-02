
module Turing #:nodoc
  def self.dir_to_amount(dir)
    if ['r','d'].include?dir then
      1
    elsif ['l','d'].include?dir then
      -1
    else
      0
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
  
  class TransFunction
    attr_reader :states

    def get(state, symbol)
      return (@states[state][symbol] or raise ExecutionEnded)
    end
    
    def set(state, symbol, rule)
      @states[state][symbol] = rule
    end

    def initialize(aut)
      @states = {}
      aut.each_line do |line|
        next if line =~ /^\s*#/
        line =~ /^\s*(\d+)\s*(\S+)\s*(\S+)\s*(l|r)\s*(\d+)(\s*(.*))?$/
        next unless $~
        state = $~[1].to_i
        symb_r = $~[2]
        symb_w = $~[3]
        dir = $~[4]
        new_state = $~[5].to_i
        if !@states[state] then
          @states[state] = Hash.new
        end
        @states[state][symb_r] = Rule.new(symb_w, dir, new_state)
      end
    end
    
    def to_s
      @states.inject("") do |string,state|
        #string + "d(#{state[0].join(',')}) = #{state[1..3].join(',')}\n"
        state[1].each do |elem, rule|
          string += "${state[0]} ${elem} ${rule.to_s}\n"
        end
      end
    end
  end
  
  class MachineState
    attr_accessor :tape, :state, :pos, :trans, :halted

    def initialize(trans, tape, state, pos)
      @trans = trans
      @tape = tape
      @state = state
      @pos = pos
      @halted = false
    end
    
    def next
      rule = @trans.get(state, @tape.get(pos))
      new_state = rule.new_state
      new_symbol =  rule.written_symbol
      newpos = Turing::dir_to_amount(rule.direction) + pos
      newtape = tape.set_at(pos, new_symbol)
      return MachineState.new(trans, newtape, new_state, newpos)
    end
  end
  
  class Tape
    attr_accessor :tape

    def initialize(t)
      @tape = t.split(//)
    end
    
    def get(pos)

      return (pos >= tape.size)? "_" : tape[pos]
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
    attr_accessor :trans, :machines
    

    def halted
      @machines[-1].halted
    end
    
    def halted=(value)
      @machines[-1].halted = value
    end

    def initialize(filename = nil)
      if filename
        File.open(filename) do |file| 
          @trans = TransFunction.new(file.read)
        end
      else
        @trans = TransFunction.new("")
      end
    end
    
    def setup(tape)
      @machines = [MachineState.new(trans, Tape.new("#" + tape), 0, 1)]
      @halted = @trans.states.empty?
    end

    def tape
      @machines[0].tape
    end

    def step(i = 1)
      return if halted
      i.times do
        begin
          machines.push(machines[-1].next) 
        rescue ExecutionEnded
          @halted = true
          return
        end
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


