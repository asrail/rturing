require 'gconf2'

module Config

  @client = GConf::Client.default
  def self.client
    @client
  end

end
