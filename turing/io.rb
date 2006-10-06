# == File input and output
#
# Turing::Machine provides two methods +read+ and +write+. Both take a
# filename as parameter, and read (or write) the machine's states from (or
# to) a file.
#
# Example:
#
#   machine = Machine.new
#   machine.read('myfile.tur') # reads states from file +myfile.tur+
#   machine.states.push(
#     :current_state => 0,
#     :read_symbol => '1',
#     :written_symbol => '0',
#     :direction => 'r',
#     :new_state => 1,
#     :comment => 'when in state 0 reading 1, write a 0, go right and change to state 1'
#   )
#   machine.write('mynewfile.tur')
#
# See Turing::Machine's <tt>read</tt> and <tt>write</tt> methods for details. 

module Turing #:nodoc:

  class Machine

    attr_accessor :states

    # reads states from +filename+. The input format is as follows:
    # * lines started with a '#', with optional leading whitespaces, are
    #   comments.
    # * each rule is formed by 5 tokens, followed by an optional comment. The
    #   tokes are (in this order):
    #   * the current state
    #   * the symbol at the tape head
    #   * the symbol that must be written
    #   * the direction the head should move to
    #   * the new state to which the machine will change.
    def read(filename)
      self.states = []
      return unless filename
      File.open(filename).each_line { |line|
        next if line =~ /^\s*#/
        line =~ /^\s*(\d+)\s*(\S+)\s*(\S+)\s*(l|r)\s*(\d+)(\s*(.*))?$/
        next unless $~
        self.states.push( {
          :original_state => $~[1].to_i,
          :read_symbol    => $~[2],
          :written_symbol => $~[3],
          :direction      => $~[4],
          :new_state      => $~[5].to_i,
          :comment        => $~[7],
        } )
      }
    end

    # writes the states to a file named by +filename+, in the format expected
    # by #read.
    def write(filename)
    end

  end

end
