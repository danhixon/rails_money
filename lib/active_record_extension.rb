module RailsMoney
  def method_missing( method_id, *args )
    method_name = method_id.to_s
    before_type_cast = method_name.chomp!("_before_type_cast")
    setter = method_name.chomp!("=")
    method_name_in_cents = "#{method_name}_in_cents"

    if @attributes.include?(method_name_in_cents)
      if setter
        # It's the "foo" setter.
        value = if args.first.kind_of?(Money)
          # It's already money - just write its cents directly
          args.first.cents
        else 
          # It's not money yet
          if (money = Money.new(args.first) rescue nil)
            # We can make money from it. Return its cents after
            # forgetting any previous bogus value,
            @attributes.delete(method_name)
            money.cents
          else
            # We can't parse it as money; write the raw thing we
            # got for form roundtripping
            @attributes[method_name] = args.first
            args.first
          end
        end
        write_attribute(method_name_in_cents,value)
      elsif before_type_cast
        # We're validating or roundtripping.
        # If someone has set foo incorrectly, return that;
        # Otherwise, if we've got a value for foo_in_cents, 
        # make Money and return that. Otherwise, return nil.
        @attributes[method_name] || \
          (@attributes[method_name_in_cents] && \
           Money.create_from_cents(@attributes[method_name_in_cents]))
      else
        # It's the "foo" getter; make it from foo_in_cents.
        cents = read_attribute(method_name_in_cents)
        Money.create_from_cents(cents) unless cents.nil?
      end
    else 
      super
    end
  end
 
  def respond_to?( method, include_private = false )
    method_name = method.to_s.chomp("=")
    @attributes.include?("#{method_name}_in_cents") || super
  end
end

ActiveRecord::Base.send :include, RailsMoney
