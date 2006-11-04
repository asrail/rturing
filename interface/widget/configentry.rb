require "gtk2"
require "interface/config"


class ConfigEntry < Gtk::Entry
  def initialize(key)
    super()
    @key = key
    if not Config::client["/apps/rturing/#{@key}"]
      Config::client["/apps/rturing/#{@key}"] = 120
    end
    self.text = Config::client["/apps/rturing/#{@key}"]
    signal_connect("key-release-event") {
      Config::client["/apps/rturing/#{@key}"] = self.text
    }
    signal_connect("destroy") {
      Config::client["/apps/rturing/#{@key}"] = self.text
    }
  end

end
