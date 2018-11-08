module Taro
  module Core
    def vector(*args)
      Hamster::Vector.new(args)
    end

    def hash h
      Hamster::Hash.new(h)
    end

    def set(*args)
      Hamster::Set.new(args)
    end

    def hash? x
      x.is_a? Hash or x.is_a? Hamster::Hash
    end

    def list? x
      x.is_a? Hamster::List
    end

    def set? x
      x.is_a? Hamster::Set
    end

    def vector? x
      x.is_a? Hamster::Vector
    end

    def array? x
      x.is_a? Array
    end

    def indexed? x
      x.is_a? Array or x.is_a? Hamster::Vector
    end

    def enum? x
      x.is_a? Enumerable
    end

    def string? x
      x.is_a? String
    end

    def symbol? x
      x.is_a? Symbol
    end

    def integer? x
      x.is_a? Integer
    end

    def numeric? x
      x.is_a? Numeric
    end

    def numeral? x
      string? x and x.numeric?
    end
    
    def boolean? x
      x == true or x == false
    end

    def instant? x
      x.is_a? Time
    end

    def uuid? x
      x.is_a? UUIDTools::UUID
    end

    def uri? x
      x.is_a? URI
    end

    def tempid? x
      indexed? x  and x[1] < 0
    end

    def ref? x
      (indexed?(x) and (x[0] == :ref or x[0] == 'ref')) or (hash?(x) and x[ID_ATTR])
    end
  end
end
