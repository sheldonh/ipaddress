require 'ipaddress/base'

module IPAddress
  class V6
    include IPAddress::Base

    private

    BLANK = ''
    COMPRESS_REGEX = /\b(0+(?::0+)+)\b/
    COMPRESSED_SEPARATOR = '::'
    LONG_FORMAT = '%04x'
    SEPARATOR = ':'
    SHORT_FORMAT = '%x'

    def bits_from_string(network)
      hexen_from_string(network).inject(0) do |bits, hex|
        bits <<= 16
        if hex.equal? 0
          bits
        else
          bits += hex.to_i(16)
        end
      end
    end

    def compress_hexen(string)
      return string unless match = find_compressible(string)
      matches = []
      offset = 0
      while match and offset <= string.size
        matches << match
        offset += match.size
        match = find_compressible(string, offset)
      end
      longest = matches.max { |a, b| a.size <=> b.size }
      string[string.index(longest), longest.size] = BLANK
      string.insert(0, SEPARATOR) if string[0] == SEPARATOR
      string << SEPARATOR if string[-1] == SEPARATOR
      string
    end

    _ruby_version = RUBY_VERSION.split('.').collect &:to_i
    if _ruby_version[0] > 1 or _ruby_version[1] >= 9 && _ruby_version[2] >= 3
      def find_compressible(string, offset = 0)
        if match_data = COMPRESS_REGEX.match(string, offset)
          match_data[0]
        end
      end
    else
      def find_compressible(string, offset = 0)
        if COMPRESS_REGEX.match(string[offset..-1])
          match_data[0]
        end
      end
    end

    def hexen_from_string(network)
      hexen = network.split(SEPARATOR)
      i = hexen.index('')
      if i.nil?
        while hexen.size < 8
          hexen << 0
        end
      else
        hexen.delete_at(i)
        while hexen.size < 8
          hexen.insert(i, 0)
        end
      end
      hexen
    end

    def initialize_from_string(string)
      network, mask = string.split('/')
      @address_bits = bits_from_string(network)
      if mask and mask.include?(SEPARATOR)
        @mask_size = size_of_dotted_mask(mask)
      else
        mask ||= self.class.protocol_bits
        @mask_size = mask.to_i
      end
    end

    # TODO investigate optimization: perform compression inside annotate_bits
    def string_representation(bits, format = :string)
      case format
      when :compressed
        compress_hexen annotate_bits(bits, 128, 16, SHORT_FORMAT, SEPARATOR)
      when :full
        annotate_bits(bits, 128, 16, LONG_FORMAT, SEPARATOR)
      when :string
        annotate_bits(bits, 128, 16, SHORT_FORMAT, SEPARATOR)
      end
    end

    def self.protocol_bits
      128
    end
  end
end

