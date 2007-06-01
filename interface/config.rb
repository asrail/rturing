
begin
  require 'gconf2'
  GCONF = false
rescue LoadError
  GCONF = false
end
  

module Config
  
  class EmptyClient
    def initialize
      @data = {}
    end
    
    def []=(key,value)
      @data[key] = value
    end
    def [](key)
      @data[key]
    end
    def set(k,v)
      self[k] = v
    end
    def get(k)
      self[k]
    end
    
  end

  if GCONF
    @client = GConf::Client.default
  else
    @client = EmptyClient.new
  end
  def self.client
    @client
  end

end
