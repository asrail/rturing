require "gtk2"
require "interface/config"

class ConfigCheckMenuItem < Gtk::CheckMenuItem
  def initialize(key, label)
    @key = key
    super(label)
    self.active = Config::client["/apps/rturing/#{key}"] == true
    signal_connect("activate") {
      Config::client["/apps/rturing/#{key}"] = self.active?
    }
  end
end

