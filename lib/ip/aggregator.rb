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
        addresses.sort { |a, b| a.network(:bits) <=> b.network(:bits) }
      when :presorted
        addresses.dup
      else
        raise ArgumentError.new("unknown input order #{order.inspect}")
      end
    end

    def try_merge(this, other)
      raise ArgumentError.new("can't aggregate IP::V4 and IP::V6 instances") unless other.is_a?(this.class)

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
