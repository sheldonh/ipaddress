require 'ipaddress/version'
require 'ipaddress/v4'
require 'ipaddress/v6'

module IPAddress
  def self.parse(string)
    if string.include?(':')
      IPAddress::V6.new(string)
    else
      IPAddress::V4.new(string)
    end
  end
end
