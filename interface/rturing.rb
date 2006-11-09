require "interface/widget/base.rb"

def main(machine, tape)
  Gtk::init
  w = JanelaPrincipal.new(machine, tape)
  Gtk.main
end

if __FILE__ == $0
  main()
end
