require_relative 'InterfaceProperty'
require_relative 'InterfaceMethod'

module OSXMemoryModules
  class InterfaceObject
    attr_accessor :instance, :base_offset

    class << self
      attr_accessor :object_properties, :static_properties, :static_base_offset, :static_instance, :object_methods, :static_methods
    end

    def initialize(instance, base_offset = nil)
      @instance = instance
      @base_offset = base_offset
    end

    module ClassMethods
      def initialize_instance_variables
        @object_properties = {}
        @object_methods = {}

        @static_properties = {}
        @static_methods = {}
        @static_base_offset = nil
        @static_instance = nil
      end

      def inherited(subclass)
        subclass.initialize_instance_variables()
      end

      def base_offset; self.static_base_offset; end
      def base_offset=(value); self.static_base_offset = value; end
      def instance; self.static_instance; end;
      def instance=(value); self.static_instance = value; end;
      def get_property_info(name); self.static_properties[name]; end
      def get_method_info(name); self.static_methods[name]; end

      def base_offset(value = nil)
        @static_base_offset = value if value
        @static_base_offset
      end

      def property(name, type, offset)
        @object_properties[name] = InterfaceProperty.new(name, type, offset)
      end

      def static_property(name, type, offset)
        @static_properties[name] = InterfaceProperty.new(name, type, offset)
      end

      def method(name, params, start_offset, return_offsets, &block)
        return_offsets = [return_offsets] unless return_offsets.kind_of? Array
        
        @object_methods[name] = InterfaceMethod.new(name, params, start_offset, return_offsets, &block)
      end

      def static_method(name, params, start_offset, return_offsets, &block)
        return_offsets = [return_offsets] unless return_offsets.kind_of? Array

        @static_methods[name] = InterfaceMethod.new(name, params, start_offset, return_offsets, &block)
      end
    end

    module InstanceMethods
      def method_missing(method_name, *arguments, &block)
        super if method_name == :get_property_info
        super if method_name == :get_method_info
        parsed_name = method_name.to_s.gsub('=', '').to_sym

        super unless get_property_info(parsed_name) || get_method_info(parsed_name)
        parse(method_name, *arguments, &block)
      end

      def respond_to?(method_name, include_private = false)
        parsed_name = method_name.to_s.gsub('=', '').to_sym
        super unless get_property_info(parsed_name) || get_method_info(parsed_name)
      end

      private

      def get(property_name)
        property = get_property_info(property_name)
        property.read(self)
      end

      def set(property_name, value)
        property = get_property_info(property_name)
        property.write(self, value)
      end

      def call_method(method_name, arguments={}, &block)
        method = get_method_info(method_name)
        method.inject_at_address(self, arguments[:inject_point], arguments, &block)
      end

      def get_property_info(name); self.class.object_properties[name]; end
      def get_method_info(name); self.class.object_methods[name]; end

      def parse(method_name, *arguments, &block)
        parsed_name = method_name.to_s.gsub('=', '').to_sym

        if get_property_info(parsed_name)
          set(parsed_name, *arguments, &block) if method_name.to_s =~ /^(.*)=$/
          get(parsed_name) unless method_name.to_s =~ /^(.*)=$/
        else
          inject_point = arguments.shift
          new_args = arguments.reduce Hash.new, :merge
          new_args[:inject_point] = inject_point

          call_method(method_name, new_args, &block)
        end
      end
    end

    extend InstanceMethods
    include InstanceMethods
    extend ClassMethods
  end
end