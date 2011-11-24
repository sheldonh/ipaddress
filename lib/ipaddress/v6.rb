require 'ipaddress/base'

module IPAddress
  class V6
    include IPAddress::Base

    def ipv4_mapped?
      return false unless @mask_size >= 96
      @address_bits & 0xffff_ffff_ffff_ffff_ffff_ffff_0000_0000 == 0x0000_0000_0000_0000_0000_ffff_0000_0000
    end

    private

    BLANK = ''
    COMPRESS_REGEX = /\b0+(?::0+)+\b/
    COMPRESSED_SEPARATOR = '::'
    FULL_FORMAT = '%04x'
    MAPPED_PREFIX_STRING = '::ffff:'
    SEPARATOR = ':'
    SHORT_FORMAT = '%x'

    def bits_from_string(network)
      hexen_from_string(network).inject(0) do |bits, hex|
        bits <<= 16
        if hex.equal?(0)
          bits
        else
          bits += hex.to_i(16)
        end
      end
    end

    def compress_hexen(string)
      return string unless match = find_compressible(string)
      longest_offset = nil
      longest_length = nil
      offset = 0
      while match and offset <= string.size
        start, stop = match.offset(0)
        length = stop - start + 1
        if longest_length.nil? or length > longest_length
          longest_offset = start
          longest_length = length
        end
        offset += stop + 1
        match = find_compressible(string, offset)
      end
      if longest_offset
        string[longest_offset, longest_length - 1] = BLANK
        string.insert(0, SEPARATOR) if string[0] == SEPARATOR
        string << SEPARATOR if string[-1] == SEPARATOR
      end
      string
    end

    _ruby_version = RUBY_VERSION.split('.').collect &:to_i
    if _ruby_version[0] > 1 or _ruby_version[1] >= 9 && _ruby_version[2] >= 3

      def find_compressible(string, offset = 0)
        COMPRESS_REGEX.match(string, offset)
      end

    else

      def find_compressible(string, offset = 0)
        COMPRESS_REGEX.match(string[offset..-1])
      end

    end

    def hexen_from_string(network)
      hexen = network.split(SEPARATOR)
      if !hexen.empty? and hexen.last.include?(DOTTED_QUAD_SEPARATOR)
        hexen[-1] = 0
        hexen << 0
      end
      i = hexen.index(BLANK)
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

    def initialize_address_bits(network)
      @address_bits = bits_from_string(network)
      if ipv4_mapped? and network.include?(DOTTED_QUAD_SEPARATOR)
        boundary = network.rindex(SEPARATOR)
        ipv4_mapped = network[boundary + 1, network.size - boundary - 1]
        @address_bits |= bits_from_dotted_quad(ipv4_mapped)
      end
    end

    def initialize_from_string(string)
      network, mask = string.split(PREFIX_SEPARATOR)
      initialize_mask_size(mask)
      initialize_address_bits(network)
    end

    def initialize_mask_size(mask)
      if mask and mask.include?(SEPARATOR)
        @mask_size = size_of_dotted_mask(mask)
      else
        mask ||= self.class.protocol_bits
        @mask_size = mask.to_i
      end
    end

    # TODO investigate optimization: perform compression inside annotate_bits
    def rfc5952_representation(bits)
      if ipv4_mapped?
        MAPPED_PREFIX_STRING + dotted_quad(@address_bits & 0xffff_ffff)
      else
        compress_hexen annotate_bits(bits, 128, 16, SHORT_FORMAT, SEPARATOR)
      end
    end

    def string_representation(bits, presentation = :string)
      case presentation
      when :full
        annotate_bits(bits, 128, 16, FULL_FORMAT, SEPARATOR)
      when :string
        rfc5952_representation(bits)
      when :uncompressed
        annotate_bits(bits, 128, 16, SHORT_FORMAT, SEPARATOR)
      else 
        raise ArgumentError.new("unknown presentation #{presentation.inspect}")
      end
    end

    def self.protocol_bits
      128
    end
  end
end

