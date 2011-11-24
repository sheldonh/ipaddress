module IP

  class Aggregator

    def aggregate(addresses, order = :unsorted)
      return addresses if addresses.size < 2
      aggregates = sorted_addresses(addresses, order)
      sweep = true

      while sweep
        sweep = false
        i, j = 0, 1
        while j < aggregates.size
          if merged = try_merge(aggregates[i], aggregates[j])
            aggregates[i] = merged
            aggregates.delete_at(j)
            sweep = true
          else
            j = (i += 1) + 1
          end
        end
      end
      aggregates
    end

    private

    def sorted_addresses(addresses, order)
      case order
      when :unsorted
        # TODO want to write addresses.sort { |a, b| a.compare_network(b) }
        addresses.sort { |a, b| a.network(:bits) <=> b.network(:bits) }
      when :presorted
        addresses.dup
      else
        raise ArgumentError.new("unknown input order #{order.inspect}")
      end
    end

    def try_merge(this, other)
      if this.is_a?(IP::V6) and other.is_a?(IP::V4)
        other = IP::V6.new(0x0000_0000_0000_0000_0000_ffff_0000_0000 | other.address(:bits), other.mask(:size) + 96)
      end
      if this.include?(other)
        if this.network?
          this
        else
          this.dup.send :modify, this.network(:bits), this.mask(:size)
        end
      elsif this.precede?(other) and this.mask(:size) == other.mask(:size)
        network_bits = this.network(:bits)
        mask_size = this.mask(:size) - 1
        if network_bits & this.class.mask_bits(mask_size) == network_bits
          this.dup.send :modify, network_bits, mask_size
        end
      end
    end

  end

end
