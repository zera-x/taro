module Subway
  META_DB_NAME    = :meta
  ID_ATTR         = :'db.id'
  IDENT_ATTR      = :'db.ident'
  VALUE_TYPE_ATTR = :'db.type'

  TBLOB    = :'db.type.blob'
  TREF     = :'db.type.ref'
  TSTRING  = :'db.type.string'
  TINTEGER = :'db.type.integer'
  TDECIMAL = :'db.type.decmimal'
  TINSTANT = :'db.type.instant'
  TUUID    = :'db.type.uuid'
  TBOOLEAN = :'db.type.boolean'
  TSYMBOL  = :'db.type.symbol'
  TURI     = :'db.type.uri'

  VALUE_TYPES = {
    TBLOB    => 0,
    TREF     => 1,
    TSTRING  => 2,
    TINTEGER => 3,
    TDECIMAL => 4,
    TINSTANT => 5,
    TBOOLEAN => 6,
    TUUID    => 7,
    TSYMBOL  => 8,
    TURI     => 9
  }

  METHODS = {
    TBLOB    => :blob,
    TREF     => :ref,
    TSTRING  => :string,
    TINTEGER => :integer,
    TDECIMAL => :decimal,
    TINSTANT => :instant,
    TBOOLEAN => :boolean,
    TUUID    => :uuid,
    TSYMBOL  => :symbol,
    TURI     => :uri
  }

  VALUE_TYPE_CODES = VALUE_TYPES.reduce({}) do |map, x|
    map.merge(x[1] => x[0])
  end

  DEFAULT_VALUE_TYPE = VALUE_TYPES[TBLOB]

  HASH_SEED = SecureRandom.hex(16).hex

  module Types
    def type_method(tcode)
      METHODS[VALUE_TYPE_CODES[tcode] || DEFAULT_VALUE_TYPE]
    end

    def from_ruby_value(value)
      case value.class
        when String
          :string
        when FalseClass
          :boolean
        when TrueClass
          :boolean
        else
          :blob 
        end
    end
  end

  class ValueTypeReader
    attr_reader :repo

    def self.init(name)
      new(Database.get(name))
    end

    def initialize(repo)
      @repo = repo;
    end

    def blob(val)
      val
    end

    def ref(val)
      @repo.entity(val.to_i)
    end

    def string(val)
      val.to_s
    end

    def integer(val)
      val.to_i
    end

    def decimal(val)
      val.to_f
    end

    def instant(val)
      DateTime.strptime('%s', val)
    end

    def boolean(val)
      val.to_s === 'N' ? false : true
    end

    def uuid(val)
      UUIDTools::UUID.parse_int(val.to_i)
    end

    def symbol(val)
      val.to_s.to_sym
    end

    def uri(val)
      URI(val.to_s)
    end
  end

  class ValueTypeWriter
    attr_reader :repo

    include Subway::Core

    def self.init(name)
      new(Database.get(name))
    end

    def initialize(repo)
      @repo = repo;
    end

    def blob(val)
      val.to_s
    end

    def ref(val)
      if indexed? val
        val[1].to_s
      else
        val[ID_ATTR].to_s
      end
    end

    def string(val)
      val
    end

    def integer(val)
      val.to_s
    end

    def decimal(val)
      val.to_s
    end

    def instant(val)
      val.strftime('%s')
    end

    def boolean(val)
      val.to_s
    end

    def uuid(val)
      val.to_i
    end

    def symbol(val)
      val.to_s
    end

    def uri(val)
      val.to_s
    end
  end

  class TypeDisplayer
    attr_reader :repo

    def self.init(name)
      new(Database.get(name))
    end

    def initialize(repo)
      @repo = repo;
    end

    def blob(val)
      val.to_s
    end

    def ref(val)
      "<a href=\"/repo/#{@repo.name}/entity/#{val}\">#{val}</a>"
    end

    def string(val)
      val
    end

    def integer(val)
      val.to_s
    end

    def decimal(val)
      val.to_s
    end

    def instant(val)
      val
    end

    def boolean(val)
      val ? "Yes" : "No"
    end

    def uuid(val)
      val.to_s
    end

    def symbol(val)
      val
    end

    def uri(val)
      "<a href=#{val}>#{val}</a>"
    end
  end
end
