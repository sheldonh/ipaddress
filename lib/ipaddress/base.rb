module IPAddress
  module Base
    include Enumerable

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
      when :compressed
        string_representation(@address_bits, :compressed)
      when :string
        string_representation(@address_bits)
      else
        raise ArgumentError.new("unknown address presentation #{presentation.inspect}")
      end
    end

    def adjacent?(other)
      precede?(other) or follow?(other)
    end

    def broadcast(presentation = :instance)
      case presentation
      when :bits
        broadcast_bits
      when :string
        string_representation(broadcast_bits)
      when :instance
        @address_bits == broadcast_bits ? self : self.class.new(broadcast_bits, @mask_size)
      end
    end

    def each(element = :host)
      range_for_each(element).each do |host|
        yield self.class.new(host, @mask_size)
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
      when :string
        string_representation mask_bits
      when :size
        @mask_size
      else
        raise ArgumentError.new("unknown mask presentation #{presentation.inspect}")
      end
    end

    def network(presentation = :instance)
      case presentation
      when :bits
        network_bits
      when :string
        string_representation(network_bits)
      when :instance
        network? ? self : self.class.new(network_bits, @mask_size)
      else 
        raise ArgumentError.new("unknown address presentation #{presentation.inspect}")
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

    def ==(other)
      @address_bits == other.address(:bits) and @mask_size == other.mask(:size)
    end

    def <=>(other)
      @address_bits <=> other.address(:bits)
    end

    module ClassMethods
      # Returns an array of the smallest number of IPAddress instances that could represent only the network space described by the
      # IPAddress instances in the given array. If the input array is already sorted by network address, an unnecessary sort operation
      # can be optimized out by passing the optional :presorted argument.
      def aggregate(addresses, order = :unsorted)
        return addresses if addresses.size < 2
        aggregates = sorted_addresses(addresses, order)
        h = 0
        sweep = true

        while sweep
          sweep = false
          j = (i = h) + 1
          while j < aggregates.size
            left = aggregates[i]
            right = aggregates[j]
            if merged = try_merge(left, right)
              aggregates[i] = merged
              aggregates.delete_at(j)
              sweep = true
            else
              h = i
              j = (i += 1) + 1
            end
          end
        end
        aggregates
      end

      def mask_bits(mask_size)
        bits = 2 ** mask_size - 1
        bits << (protocol_bits - mask_size)
      end

      private

      def sorted_addresses(addresses, order)
        case order
        when :unsorted
          addresses.sort { |a, b| a.network(:bits) <=> b.network(:bits) }
        when :presorted
          addresses.dup
        else
          raise ArgumentError.new("unknown input order #{order.inspect}")
        end
      end

      def try_merge(this, other)
        if this.include?(other)
          if this.network?
            this
          else
            this.dup.send :modify, this.network(:bits), this.mask(:size)
          end
        elsif this.precede?(other) and this.mask(:size) == other.mask(:size)
          network_bits = this.network(:bits)
          mask_size = this.mask(:size) - 1
          if network_bits & mask_bits(mask_size) == network_bits
            this.dup.send :modify, network_bits, mask_size
          end
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    private

    def annotate_bits(bits, size, width, base, separator)
      shift = size - width
      size -= width
      s = (bits >> shift).to_s(base)
      while size >= width
        mask = 2 ** size - 1
        shift = (size -= width)
        s << separator
        s << ((bits & mask) >> shift).to_s(base)
      end
      s
    end

    def broadcast_bits
      network_bits + 2 ** (self.class.protocol_bits - @mask_size) - 1
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
    def string_representation(bits, format = :string)
      raise NotImplementedError
    end
  end
end
