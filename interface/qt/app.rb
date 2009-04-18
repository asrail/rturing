require 'Qt4'
require 'mainwindow'
require 'machineviewer'

def main(machine, tape)
  app = Qt::Application.new(ARGV)
  
  mw = MainWindow.new(machine, tape)
  mw.show()

  app.exec()
end

if __FILE__ == $0
  main(nil, nil)
end
