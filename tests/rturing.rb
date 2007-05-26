# This files contains testcases for the Turing::Machine class
require 'test/unit'
require 'turing/machine'

class MachineTests < Test::Unit::TestCase #:nodoc:
  def test_input_tape
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/add.tur')
    machine.setup('01010',false)
    assert_equal(['#', '0', '1', '0', '1', '0'], machine.tape.tape)
  end

  def test_three_ones_to_zeros
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/3ones2zeroes.tur')
    machine.setup('1110111',false)
    machine.process
    assert_equal(['#', '0', '0', '0', '0', '0', '0', '0' ], machine.tape.tape)
    assert(machine.halted)
  end

  def test_empty
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file("machines/empty.tur")
    machine.setup('0')
    assert(machine.on_start?)
    assert(machine.halted)
  end

  def test_step
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/swap.tur')
    machine.setup('0101',false)
    machine.process
    assert_equal(['#', '1','0','1','0'], machine.tape.tape)
    machine.setup('1010')
    machine.process
    assert_equal(['0','1','0','1'], machine.tape.tape)
  end

  def test_add
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/add.tur')
    machine.setup('01010')
    machine.process
    assert_equal(['0','1','1','0','_'], machine.tape.tape)
  end

  def test_next
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/swap.tur')
    machine.setup('01010',false)
    machine.step
    assert(!machine.halted)
  end
  
  def test_prev
    machine = Turing::Machine.from_file('machines/add.tur', Model::gturing)
    machine.setup('011010')
    5.times { machine.step }
    5.times { machine.unstep }
    assert_equal(machine.tape.tape, machine.first_tape.tape)
  end

  def test_both_sides
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur')
    machine.setup('')
    5.times { machine.step }
    assert_equal(['_', '0', '0', '0', '0', '0'], machine.tape.tape)
    5.times {machine.unstep }
    assert_equal("", machine.tape.tape.to_s.gsub(/(^( |_)*)|(( |_)*$)/, ""))
  end

  def test_non_det
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/all_the_way_nondet.tur')
    machine.setup('')
    m1 = machine.step[0]
    assert_equal(['_', '1'], m1.tape.tape)
    assert_equal(['_', '0'], machine.tape.tape)
    #puts "mi.tape: #{m1.tape}"
    #puts "machine.tape: #{machine.tape}"
  end


  def test_stress
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur')
    machine.setup('')
    10000.times { machine.step }
    10000.times { machine.unstep }
    assert_equal("", machine.tape.tape.to_s.gsub(/(^( |_)*)|(( |_)*$)/, ""))
  end

  def test_alpha
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/swap_alpha.tur')
    machine.setup('abab',true)
    machine.process
    assert_equal(['b','a','b','a'], machine.tape.tape)
  end

  def test_alpha2
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/swap_alpha2.tur')
    machine.setup('abab',true)
    machine.process
    assert_equal(['b','a','b','a'], machine.tape.tape)
  end

  def test_all_left_return
    Turing::Machine.default_kind = "Gturing"
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur', nil, true)
    machine.setup('')
    Turing::Machine.toggle_both_sides
    assert_equal([], machine.tape.tape)
    machine.step
    assert_equal(['0'], machine.tape.tape)
    machine.step
    assert_equal(['0'], machine.tape.tape)
    machine.unstep
    assert_equal(['0'], machine.tape.tape)
    machine.unstep
    assert_equal(['0'], machine.tape.tape)
    Turing::Machine.toggle_both_sides
  end

  def test_wies_palin
    Turing::Machine.default_kind = "Wiesbaden"
    machine = Turing::Machine.from_file('machines/wies_palin.tur')
    machine.setup('_AAABBAAA')
    machine.process
    assert_equal(['_','Y','E', 'S', '_', '_', '_', '_', '_', '_'], machine.tape.tape)
  end
end
