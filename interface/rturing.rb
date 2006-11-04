require "interface/widget/base.rb"

def main
  Gtk::init
  w = JanelaPrincipal.new
  Gtk.main
end

if __FILE__ == $0
  main()
end
