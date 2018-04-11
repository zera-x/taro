module Subway
  # Perl Data Notation
  class PDN
    def self.decode(str)
      eval(str)
    end

    def self.encode(x)
      x.to_perl
    end

    private

    def self.undef
      nil
    end
  end
end

class Time
  def to_perl
    "'#{self.strftime('%FT%T')}'"
  end
end

class Object
  def to_perl
    "'#{to_s.gsub(/'/, '\\\'')}'"
  end
end

class NilClass
  def to_perl
    'undef'
  end
end

class FalseClass
  def to_perl
    '0'
  end
end

class TrueClass
  def to_perl
    '1'
  end
end

class Numeric
  def to_perl
    self.to_s
  end
end

module PerlEnumerable
  def to_perl
    "[#{self.map { |x| x.to_perl }.join(', ')}]"
  end
end

module Enumerable
  include PerlEnumerable
end

class Array
  include PerlEnumerable
end

class Hamster::Set
  include PerlEnumerable
end

class Hash
  def to_perl
    "{#{self.map { |k, v| "#{k.to_perl} => #{v.to_perl}" }.join(', ')}}"
  end
end

class Hamster::Hash
  def to_perl
    "{#{self.map.map { |kv| "#{kv[0].to_perl} => #{kv[1].to_perl}" }.join(', ')}}"
  end
end

class Hamster::Set
  def to_perl
    "[#{self.map.map(&:to_perl).join(', ')}]"
  end
end

class Hamster::Vector
  def to_perl
    "[#{self.map.map(&:to_perl).join(', ')}]"
  end
end
