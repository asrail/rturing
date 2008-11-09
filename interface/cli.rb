require 'getoptlong'
require 'rdoc/usage'
require 'turing/machine'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--interactive-mode', '-i', GetoptLong::REQUIRED_ARGUMENT],
  [ '--both', '-b', GetoptLong::NO_ARGUMENT ]
)

interactive_mode = true
both = nil
opts.each do |opt, arg|
  case opt
    when '--help'
      RDoc::usage
    when '--interactive-mode'
      if arg =~ /[yYnN]/
        interactive_mode = nil if arg =~ /[nN]/
      else
        RDoc::usage
      end
    when '--both'
      both = true
  end
end

if ARGV.length != 2
  puts "Faltando argumentos (tente --help)"
  RDoc::usage
end

file_mt = ARGV.shift
tape = ARGV.shift

machine = Turing::Machine.from_file(file_mt)
machine.setup(tape, both)
machine.process(interactive_mode ? :print : nil)
machine.print unless interactive_mode
