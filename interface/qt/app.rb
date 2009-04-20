require 'Qt4'
require 'mainwindow'
require 'machineviewer'

def main(machine, tape)
  app = Qt::Application.new(ARGV)
  Qt::TextCodec::setCodecForTr(Qt::TextCodec::codecForName("utf8"))

  mw = MainWindow.new(machine, tape)
  mw.show()

  app.exec()
end

if __FILE__ == $0
  main(ARGV[0], ARGV[1])
end
