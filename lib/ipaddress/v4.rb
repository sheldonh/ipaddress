require 'ipaddress/base'

module IPAddress
  class V4
    include IPAddress::Base

    private

    MASK_OCTET_WIDTH = {
      254 => 7,
      252 => 6,
      248 => 5,
      240 => 4,
      224 => 3,
      192 => 2,
      128 => 1,
    }

    OCTET_SEPARATOR = '.'

    # :nodoc:
    def bits_from_dotted_quad(dotted_quad)
      octets = dotted_quad.split(OCTET_SEPARATOR).collect &:to_i
      octets.inject(octets.shift) do |bits, octet|
        bits <<= 8
        bits += octet
      end
    end

    def initialize_from_string(string)
      network, mask = string.split(PREFIX_SEPARATOR)
      @address_bits = bits_from_dotted_quad(network)
      if mask
        if mask.include?(OCTET_SEPARATOR)
          @mask_size = size_of_dotted_mask(mask)
        else
          @mask_size = mask.to_i
        end
      else
        @mask_size = self.class.protocol_bits
      end
    end

    # :nodoc:
    def size_of_dotted_mask(dotted_quad)
      size = 0
      octets = dotted_quad.split(OCTET_SEPARATOR).collect &:to_i
      octets.each do |octet|
        if octet == 255
          size += 8
        else
          if octet > 0
            size += MASK_OCTET_WIDTH[octet]
          end
          break
        end
      end
      size
    end

    def string_representation(bits, format = :unused)
      annotate_bits bits, 32, 8, 10, OCTET_SEPARATOR
    end

    def self.protocol_bits
      32
    end
  end
end
