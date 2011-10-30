require 'ipaddress/version'

class IPAddress
  include Enumerable

  def initialize(*args)
    case args.size
    when 2
      @address_bits, @mask_size = args
    else
      initialize_from_string(*args)
    end
  end

  def address(presentation = :dotted)
    case presentation
    when :bits
      @address_bits
    when :dotted
      dotted_quad_from_bits(@address_bits)
    else
      raise ArgumentError.new("unknown address presentation #{presentation.inspect}")
    end
  end

  def adjacent?(other)
    broadcast_bits.succ == other.network(:bits) or network_bits == other.broadcast(:bits).succ
  end

  def broadcast(presentation = :instance)
    case presentation
    when :bits
      broadcast_bits
    when :dotted
      dotted_quad_from_bits(broadcast_bits)
    when :instance
      @address_bits == broadcast_bits ? self : self.class.new(broadcast_bits, @mask_size)
    end
  end

  def each(element = :host)
    case element
    when :address
      addresses = 2 ** (32 - @mask_size)
      addresses.times do |i|
        yield self.class.new(network_bits + i, @mask_size)
      end
    when :host
      host = network_bits + 1
      while host < broadcast_bits
        yield self.class.new(host, @mask_size)
        host += 1
      end
    else
      raise ArgumentError.new("unknown element type #{element.inspect}")
    end
  end

  def host?
    if @mask_size == 32 or @mask_size == 0 or @address_bits != network_bits
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
    when :dotted
      dotted_quad_from_bits mask_bits
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
    when :dotted
      dotted_quad_from_bits(network_bits)
    when :instance
      network? ? self : self.class.new(network_bits, @mask_size)
    else 
      raise ArgumentError.new("unknown address presentation #{presentation.inspect}")
    end
  end

  def network?
    if @mask_size == 32 or @mask_size == 0
      false
    elsif @address_bits == network_bits
      true
    end
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

  # Returns an array of the smallest number of IPAddress instances that could represent only the network space described by the
  # IPAddress instances in the given array. If the input array is already sorted by network address, an unnecessary sort operation
  # can be optimized out by passing the optional :presorted argument.
  def self.aggregate(addresses, order = :unsorted)
    return addresses if addresses.size < 2
    sorted = sorted_addresses(addresses, order)
    aggregates = [ sorted.first ]
    dup_first = true
    (1..sorted.size - 1).each do |i|
      if merged = try_merge(aggregates[-1], sorted[i], dup_first)
        dup_first = merged.equal?(aggregates[-1])
        aggregates[-1] = merged
      else
        dup_first = true
        aggregates << sorted[i]
      end
    end
    aggregates
  end

  # :nodoc:
  def self.mask_bits(mask_size)
    bits = 2 ** mask_size - 1
    bits << (32 - mask_size)
  end

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

  def bits_from_dotted_quad(dotted_quad)
    octets = dotted_quad.split('.').collect &:to_i
    octets.inject(octets.shift) do |bits, octet|
      bits <<= 8
      bits += octet
    end
  end

  def broadcast_bits
    network_bits + 2 ** (32 - @mask_size) - 1
  end

  def dotted_quad_from_bits(bits)
    s = (bits >> 24).to_s
    s << OCTET_SEPARATOR
    s << ((bits & (2 ** 24 - 1)) >> 16).to_s
    s << OCTET_SEPARATOR
    s << ((bits & (2 ** 16 - 1)) >> 8).to_s
    s << OCTET_SEPARATOR
    s << (bits & (2 ** 8 - 1)).to_s
  end

  def initialize_from_string(string)
    network, mask = string.split('/')
    @address_bits = bits_from_dotted_quad(network)
    if mask and mask.include?('.')
      @mask_size = size_of_dotted_mask(mask)
    else
      mask ||= 32
      @mask_size = mask.to_i
    end
  end

  def mask_bits
    self.class.mask_bits @mask_size
  end

  def network_bits
    @address_bits & mask_bits
  end

  def size_of_dotted_mask(dotted_quad)
    size = 0
    octets = dotted_quad.split('.').collect &:to_i
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

  def self.modify(this, address_bits, mask_size, dup_first)
    this = this.dup if dup_first
    this.instance_variable_set :@address_bits, address_bits
    this.instance_variable_set :@mask_size, mask_size
    this
  end

  def self.sorted_addresses(addresses, order)
    case order
    when :unsorted
      addresses.sort { |a, b| a.network(:bits) <=> b.network(:bits) }
    when :presorted
      addresses
    else
      raise ArgumentError.new("unknown input order #{order.inspect}")
    end
  end

  def self.try_merge(this, other, dup_first)
    if this.include?(other)
      if this.network?
        this
      else
        modify this, this.network(:bits), this.mask(:size), dup_first
      end
    elsif this.adjacent?(other) and this.mask(:size) == other.mask(:size)
      network_bits = this.network(:bits)
      mask_size = this.mask(:size) - 1
      if network_bits & mask_bits(mask_size) == network_bits
        modify this, network_bits, mask_size, dup_first
      end
    end
  end
end
