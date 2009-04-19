require 'Qt4'
require 'turing/machine'

class MainWindow < Qt::MainWindow
  attr_accessor :light_mode, :file, :both_sides
  attr_reader :timeout, :both_sides, :mview

  def initialize(m, t, parent = nil)
    super()
    self.windowTitle = tr("gRats")
    self.light_mode = false
    Turing::Machine.default_kind = "gturing"
    self.both_sides = false #Config::client["/apps/rturing/mboth"]
    @saved = true
    begin
      machine = Turing::Machine.from_file(m, Turing::Machine.default_kind, self.both_sides)
    rescue
      machine = Turing::Machine.new("", self.both_sides, Turing::Machine.default_kind)
    end
    machine.setup((t or ""))
    @mview = MachineViewer.new(machine, self)
    @mview.update_labels
    vp = Qt::VBoxLayout.new
    vp.addLayout(mview)
    central = Qt::Widget.new
    central.setLayout(vp)
    setCentralWidget(central)
  end
end

