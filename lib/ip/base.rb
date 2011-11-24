require 'ip/aggregator'

module IP
  module Base
    include Enumerable

    DOTTED_QUAD_FORMAT = '%d'
    DOTTED_QUAD_SEPARATOR = '.'
    PREFIX_SEPARATOR = '/'

    def initialize(*args)
      case args.size
      when 2
        @address_bits, @mask_size = args
      else
        initialize_from_string(*args)
      end
    end

    def address(presentation = :string)
      case presentation
      when :bits
        @address_bits
      else
        string_representation @address_bits, presentation
      end
    end

    def adjacent?(other)
      precede?(other) or follow?(other)
    end

    def broadcast(presentation = :instance)
      case presentation
      when :bits
        broadcast_bits
      when :instance
        @address_bits == broadcast_bits ? self : self.class.new(broadcast_bits, @mask_size)
      else
        string_representation broadcast_bits, presentation
      end
    end

    def each(element = :host, &block)
      if host?
        yield self
      else
        case element
        when :address
          each_address &block
        when :host
          each_host &block
        else
          raise ArgumentError.new("unknown element type #{element.inspect}")
        end
      end
    end

    def follow?(other)
      network(:bits) == other.broadcast(:bits).succ
    end

    def host?
      if @mask_size == self.class.protocol_bits or @mask_size == 0 or @address_bits != network_bits
        true
      else
        false
      end
    end

    def include?(other)
      if other.host?
        other_address = other.send(:address, :bits)
        network_bits <= other_address and broadcast_bits >= other_address
      else
        network_bits <= other.send(:network_bits) and broadcast_bits >= other.send(:broadcast_bits)
      end
    end

    def mask(presentation = :size)
      case presentation
      when :bits
        mask_bits
      when :size
        @mask_size
      else
        string_representation mask_bits, presentation
      end
    end

    def network(presentation = :instance)
      case presentation
      when :bits
        network_bits
      when :instance
        network? ? self : self.class.new(network_bits, @mask_size)
      else
        string_representation network_bits, presentation
      end
    end

    def network?
      if @mask_size == self.class.protocol_bits or @mask_size == 0
        false
      elsif @address_bits == network_bits
        true
      end
    end

    def precede?(other)
      broadcast_bits.succ == other.network(:bits)
    end

    def to_s
      "#{address}/#{mask}"
    end

    def to_v6
      if is_a?(IP::V4)
        IP::V6.new(0x0000_0000_0000_0000_0000_ffff_0000_0000 | @address_bits, 96 + @mask_size)
      else
        self
      end
    end

    def ==(other)
      if self.is_a?(IP::V6) or other.is_a?(IP::V6)
        this, that = self.to_v6, other.to_v6
        this.address(:bits) == that.address(:bits) and this.mask(:size) == that.mask(:size)
      else
        @address_bits == other.address(:bits) and @mask_size == that.mask(:size)
      end
    end

    def <=>(other)
      if self.is_a?(IP::V6) or other.is_a?(IP::V6)
        self.to_v6.address(:bits) <=> other.to_v6.address(:bits)
      else
        @address_bits <=> other.address(:bits)
      end
    end

    module ClassMethods

      def aggregate(addresses, order = :unsorted)
        IP::Aggregator.new.aggregate addresses, order
      end

      def mask_bits(mask_size)
        bits = 2 ** mask_size - 1
        bits << (protocol_bits - mask_size)
      end

    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    private

    def annotate_bits(bits, size, width, format, separator)
      shift = size - width
      size -= width
      s = format % (bits >> shift)
      while size >= width
        mask = 2 ** size - 1
        shift = (size -= width)
        s << separator
        s << format % ((bits & mask) >> shift)
      end
      s
    end

    # :nodoc:
    def bits_from_dotted_quad(dotted_quad)
      octets = dotted_quad.split(DOTTED_QUAD_SEPARATOR).collect &:to_i
      octets.inject(octets.shift) do |bits, octet|
        bits <<= 8
        bits += octet
      end
    end

    def broadcast_bits
      network_bits + 2 ** (self.class.protocol_bits - @mask_size) - 1
    end

    def dotted_quad(bits)
      annotate_bits(bits, 32, 8, DOTTED_QUAD_FORMAT, DOTTED_QUAD_SEPARATOR)
    end

    def each_host
      if network_size == 2
        start = network_bits
        stop = broadcast_bits
      else
        start = network_bits + 1
        stop = broadcast_bits - 1
      end
      start.upto(stop) do |host|
        yield self.class.new(host, @mask_size)
      end
    end

    def each_address
      network_bits.upto(broadcast_bits) do |host|
        yield self.class.new(host, @mask_size)
      end
    end

    # V4 and V6 implement this
    def initialize_from_string(string)
      raise NotImplementedError
    end

    def mask_bits
      self.class.mask_bits @mask_size
    end

    def modify(address_bits, mask_size)
      instance_variable_set :@address_bits, address_bits
      instance_variable_set :@mask_size, mask_size
      self
    end

    def network_bits
      @address_bits & mask_bits
    end

    def network_size
      2 ** (self.class.protocol_bits - @mask_size)
    end

    # V4 and V6 implement this
    def protocol_bits
      raise NotImplementedError
    end

    def range_for_each(element)
      case element
      when :address
        network_bits..broadcast_bits
      when :host
        if network_size > 2
          (network_bits + 1)..(broadcast_bits - 1)
        elsif network_size == 2
          # PPP network has no network/broadcast addresses
          (network_bits..broadcast_bits)
        else
          @address_bits..@address_bits
        end
      else
        raise ArgumentError.new("unknown element type #{element.inspect}")
      end
    end

    # V4 and V6 implement this in terms of annotate_bits
    def string_representation(bits, presentation = :string)
      raise NotImplementedError
    end
  end
end
