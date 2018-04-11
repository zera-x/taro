module Subway
  class Database
    class Entity
      attr_reader :dbid
  
      def initialize(id, db)
        @dbid  = id
        @db    = db
      end
  
      def to_h
        e = db.facts(@dbid).reduce({}) do |emap, r|
          emap.merge(r[:attr].to_sym => db.read_value(r[:valType], r[:val]))
        end
        e[ID_ATTR] = eid
      end

      alias force to_h
    end
  end
end
