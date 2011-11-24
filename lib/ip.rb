require 'ip/version'
require 'ip/v4'
require 'ip/v6'

module IP
  def self.parse(string)
    if string.include?(':')
      IP::V6.new(string)
    else
      IP::V4.new(string)
    end
  end
end
