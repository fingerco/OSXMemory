module OSXMemoryModules
  class InterfaceProperty
    attr_accessor :name, :type, :offset    

    PACKERS = {
      uint: {packer: 'L', default_size: 4},
      int: {packer: 'l', default_size: 4},
      bool: {packer: 'C', default_size: 1},
      float: {packer: 'F', default_size: 4},
      address: {packer: 'Q', default_size: 8},
      string: {packer:'Z*', default_size: 100}
    }

    def initialize(name, type, offset)
      @name = name
      @type = type
      @offset = offset
    end

    def read(interface_object, size = nil)
      self.class.read_with_type(interface_object.instance, @type, interface_object.base_offset + @offset, size)
    end

    def write(interface_object, value)
      write_address = interface_object.base_offset + @offset
      type = @type

      if @type == :string
        string_data = pack(value)
        new_string_address = interface_object.instance.alloc(string_data.size)
        interface_object.instance.write(new_string_address, string_data)

        type = :address
        value = new_string_address
      end

      interface_object.instance.write(write_address, pack_with_type(type, value))
    end

    def self.read_with_type(instance, property_type, addr, size = nil)
      if property_type == :string
        addr = instance.read(addr, PACKERS[:address][:default_size]).unpack(PACKERS[:address][:packer]).first
      end

      size ||= PACKERS[property_type][:default_size]
      instance.read(addr, size).unpack(PACKERS[property_type][:packer]).first
    end

    def self.pack_with_type(type, value); [value].pack(PACKERS[type][:packer]); end

    private

    def pack(value); self.class.pack_with_type(@type, value); end

  end
end