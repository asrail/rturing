require "interface/widget/base.rb"

def main(machine, tape)
  Gtk::init
  w = MainWindow.new(machine, tape)
  Gtk.main
end

if __FILE__ == $0
  main()
end
