module OSXMemoryModules
  class FFIStruct < FFI::Struct
    def methods(regular=true)
      (super + self.members.map{|x| [x, (x.to_s+"=").intern]}).flatten
    end

    def method_missing(meth, *args)
      super unless self.respond_to? meth
      if meth.to_s =~ /=$/
        self.__send__(:[]=, meth.to_s.gsub(/=$/,'').intern, *args)
      else
        self.__send__(:[], meth, *args)
      end
    end

    def respond_to?(meth, include_priv=false)
      !((self.methods & [meth, meth.to_s]).empty?) || super
    end
  end
end