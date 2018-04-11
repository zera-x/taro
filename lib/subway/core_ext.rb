class String
  def numeric?
    !!self.match(/^[0-9]+$/)
  end
end

module Unific
  class Env
    def to_hash
      buffer = []
      bindings.each do |var|
        buffer.push([var, self[var]])
      end
      Hamster::Hash.new(buffer)
    end
  end
end

class Hamster::Set
  def to_json(*args)
    to_a.to_json(*args)
  end
end

class Hamster::Vector
  def to_json(*args)
    to_a.to_json(*args)
  end
end
