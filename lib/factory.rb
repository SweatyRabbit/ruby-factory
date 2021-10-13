# frozen_string_literal: true

# * Here you must define your `Factory` class.
# * Each instance of Factory could be stored into variable. The name of this variable is the name of created Class
# * Arguments of creatable Factory instance are fields/attributes of created class
# * The ability to add some methods to this class must be provided while creating a Factory
# * We must have an ability to get/set the value of attribute like [0], ['attribute_name'], [:attribute_name]
#
# * Instance of creatable Factory class should correctly respond to main methods of Struct
# - each
# - each_pair
# - dig
# - size/length
# - members
# - select
# - to_a
# - values_at
# - ==, eql?

class Factory
  def self.new(*args, &block)
    class_name = args.shift.capitalize if args[0].is_a?(String)
    new_class = Class.new do
      args.each { |x| attr_accessor x }

      define_method :initialize do |*attr|
        raise ArgumentError if attr.length > args.length

        args.each.with_index do |arg, i|
          instance_variable_set("@#{arg}", (attr[i] || nil))
        end
      end

      def ==(other)
        if other.is_a? self.class
          instance_variables.each do |variable|
            return false if instance_variable_get(variable) != other.instance_variable_get(variable)
          end
          true
        else
          false
        end
      end

      def [](variable)
        return instance_variable_get("@#{variable}") if variable.is_a? String
        return instance_variable_get("@#{variable}") if variable.is_a? Symbol
        return instance_variable_get(instance_variables[variable]) if variable.is_a? Integer
      end

      def []=(variable, value)
        instance_variable_set("@#{variable}", value) if variable.is_a? String
        instance_variable_set("@#{variable}", value) if variable.is_a? Symbol
        instance_variable_set(instance_variables[variable], value) if variable.is_a? Integer
      end

      def members
        instance_variables.map { |attribute| attribute.to_s.delete('@').to_sym }
      end

      def to_a
        instance_variables.map { |attr| instance_variable_get(attr) }
      end

      def values_at(*index)
        result = instance_variables.map { |attr| instance_variable_get(attr) }
        index.map { |selector| result[selector] }
      end

      def each
        instance_variables.map { |attr| yield(instance_variable_get(attr)) }
      end

      def each_pair
        instance_variables.map { |elem| yield(elem.to_s.delete('@'), instance_variable_get(elem)) }
      end

      def size
        instance_variables.size
      end
      alias_method :length, :size

      def dig(key, *val)
        value = self[key]
        if value.nil?
          value
        elsif value.respond_to?(:dig)
          value.dig(*val)
        end
      end

      def select
        result = instance_variables.map do |attribute|
          instance_variable_get(attribute) if yield(instance_variable_get(attribute))
        end
        result.compact
      end

      class_eval(&block) if block_given?
    end

    const_set(class_name, new_class) if class_name
    new_class
  end
end
