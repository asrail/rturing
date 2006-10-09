# This files implements the logic that drives the Turing machine into the
# Turing::Machine class.

require 'turing/io'
require 'observer'

module Turing #:nodoc:

  # == Theory of operation
  #
  # _To_ _be_ _written_.
  #
  class Machine

    include Observable

    attr_accessor :current_state
    attr_accessor :tape
    attr_accessor :tape_position

    def setup(input_tape)
      self.tape = input_tape.split(//)
      self.current_state = 0
      self.tape_position = 0
    end

    def process
      while(! self.halted)
        changed; notify_observers(self)
        self.step
      end
      changed; notify_observers(self)
    end

    def current_symbol
      tape[tape_position]
    end

    def current_symbol=(symbol)
      tape[tape_position] = symbol
    end

    def step
      rule = self.find_rule(self.current_state, self.current_symbol)
      if rule
        self.current_state = rule[:new_state] 
        self.current_symbol = rule[:written_symbol]
        self.tape_position = (rule[:direction] == 'l') ? (tape_position-1) : (tape_position+1)
      end
    end

    def initialize(filename = nil)
      if filename
        read(filename)
      else
        self.states = []
      end
    end

    def to_s
      states.map { |s|
        "d(#{s[:original_state]},#{s[:read_symbol]}) = (#{s[:written_symbol]},#{s[:direction]},#{s[:new_state]}) ##{s[:comment]}"
      }.join("\n")
    end

    def find_rule(state,symbol)
      states.find { |s|
        s[:original_state] == state && s[:read_symbol] == symbol
      }
    end

    def halted
      find_rule(current_state, tape[tape_position]) == nil
    end

  end

end
