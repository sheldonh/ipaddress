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

  def broadcast
    if @address_bits == broadcast_bits
      self
    else
      self.class.new(broadcast_bits, @mask_size)
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
    when :size
      @mask_size
    when :bits
      mask_bits(@mask_size)
    when :dotted
      dotted_quad_from_bits(mask_bits(@mask_size))
    else
      raise ArgumentError.new("unknown mask presentation #{presentation.inspect}")
    end
  end

  def network
    if network?
      self
    else
      self.class.new(network_bits, @mask_size)
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

  def mask_bits(mask_size)
    bits = 2 ** mask_size - 1
    bits << (32 - mask_size)
  end

  def network_bits
    @address_bits & mask_bits(@mask_size)
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
end
