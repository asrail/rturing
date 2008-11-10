# This files contains testcases for the Turing::Machine class
require 'test/unit'
require 'turing/machine'

class MachineTests < Test::Unit::TestCase #:nodoc:
  def test_a_sub_machine
    machine = Turing::Machine.from_file('machines/submaquina.tur', "Gturing")
    machine.setup('0',true)
    machine.process
    assert_equal(['_','0','0','0', '0'], machine.tape.tape)
  end

  def test_input_tape
    machine = Turing::Machine.from_file('machines/add.tur', "Gturing")
    machine.setup('01010', false)
    assert_equal(['#', '0', '1', '0', '1', '0'], machine.tape.tape)
  end

  def test_three_ones_to_zeros
    machine = Turing::Machine.from_file('machines/3ones2zeroes.tur', "Gturing", false)
    machine.setup('1110111')
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
    machine = Turing::Machine.from_file('machines/swap.tur', "Gturing", false)
    machine.setup('0101')
    machine.process
    assert_equal(['#', '1','0','1','0'], machine.tape.tape)
    machine.setup('1010', true)
    machine.process
    assert_equal(['0','1','0','1'], machine.tape.tape)
  end

  def test_add
    machine = Turing::Machine.from_file('machines/add.tur', "Gturing", true)
    machine.setup('01010')
    machine.process
    assert_equal(['0','1','1','0','_'], machine.tape.tape)
  end

  def test_next
    machine = Turing::Machine.from_file('machines/swap.tur', "Gturing", false)
    machine.setup('01010')
    machine.step
    assert(!machine.halted)
  end

  def test_multi_recurse
    machine = Turing::Machine.from_file('machines/quadrifurca.tur', "Gturing", false)
    machine.setup('01 00 11 10')
    machine.process
  end
  
  def test_prev
    machine = Turing::Machine.from_file('machines/add.tur', "Gturing")
    machine.setup('011010')
    5.times { machine.step }
    5.times { machine.unstep }
    assert_equal(machine.tape.tape, machine.first_tape.tape)
  end

  def test_recurse
    machine = Turing::Machine.from_file('machines/recursive.tur', "Gturing")
    machine.setup('00000')
    machine.process
    assert_equal(machine.tape.tape, ['#','a','a','a','a','a', '_'])
  end

  def test_both_sides
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur', "Gturing", true)
    machine.setup('')
    5.times { machine.step }
    assert_equal(['_', '0', '0', '0', '0', '0'], machine.tape.tape)
    5.times {machine.unstep }
    assert_equal("", machine.tape.tape.to_s.gsub(/(^( |_)*)|(( |_)*$)/, ""))
  end

  def test_stress
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur', "Gturing", true)
    machine.setup('')
    10000.times { machine.step }
    10000.times { machine.unstep }
    assert_equal("", machine.tape.tape.to_s.gsub(/(^( |_)*)|(( |_)*$)/, ""))
  end

  def test_alpha
    machine = Turing::Machine.from_file('machines/swap_alpha.tur', "Gturing")
    machine.setup('abab',true)
    machine.process
    assert_equal(['b','a','b','a'], machine.tape.tape)
  end

  def test_alpha2
    machine = Turing::Machine.from_file('machines/swap_alpha2.tur', "Gturing")
    machine.setup('abab',true)
    machine.process
    assert_equal(['b','a','b','a'], machine.tape.tape)
  end

  def test_all_left_return
    machine = Turing::Machine.from_file('machines/all_the_way_left.tur', "Gturing", false)
    machine.setup('')
    machine.toggle_both_sides
    assert_equal([], machine.tape.tape)
    machine.step
    assert_equal(['_', '0'], machine.tape.tape)
    machine.step
    assert_equal(['_', '0', '0'], machine.tape.tape)
    machine.unstep
    assert_equal(['_', '0'], machine.tape.tape)
    machine.unstep
    assert_equal(['_'], machine.tape.tape)
    machine.toggle_both_sides
  end

  def test_wies_palin
    machine = Turing::Machine.from_file('machines/wies_palin.tur', "Wiesbaden", true)
    machine.setup('_AAABBAAA')
    machine.process
    assert_equal(['_','Y','E', 'S', '_', '_', '_', '_', '_', '_'], machine.tape.tape)
  end
end
