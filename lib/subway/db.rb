require_relative 'transactor'

module Subway
  class Database
    include Enumerable
    include Subway::Types
    include Subway::Core

    attr_reader :name
    
    ASSERT_IDENT  = :'db.assert'
    RETRACT_IDENT = :'db.retract'

    class DatabaseError < Exception; end
    class TransactionError < DatabaseError; end

    class << self
      def all
        DB.tables.map { |r| get(r) }
      end
  
      def get(name)
        name =
          if name.is_a? Symbol
            name
          elsif name.is_a? String
            name.to_sym
          else
            raise 'name should be a symbol or a string'
          end
        @dbs ||= {}
        @dbs[name] ||= new(name, DB[name])
      end
      alias [] get
  
      def meta
        @meta ||= make(META_DB_NAME)
      end
  
      def make(name)
        DB.create_table? name do
          Bignum      :tx
          DateTime    :t,       :null => false
          Boolean     :retract, :null => false, :default => false
          Bignum      :eid,     :null => false
          String      :attr,    :null => false
          Integer     :valType, :null => false, :default => DEFAULT_VALUE_TYPE
          Boolean     :many,    :null => false, :default => false
          blob        :val,     :null => false
          primary_key [:tx, :t, :retract, :eid, :attr, :valType, :many, :val]
        end
    
        get(name)
      end
    end

    def initialize(name, dataset)
      @name    = name
      @dataset = dataset
      @writer = ValueTypeWriter.new(self)
      @reader = ValueTypeReader.new(self)
    end

    def txs
      @dataset.lazy
    end

    def tx(tid)
      @txs ||= {}
      @txs[tid] = @dataset.where(:tx => tid).lazy
    end

    def facts(eid=nil, attr=nil, val=nil)
      data = @dataset
      data = eid ? data.where(:eid => resolve_eid(eid)) : data
      data = attr ? data.where(:attr => attr.to_s) : data
      data = val ? data.where(Sequel.like(:val, "#{val}%")) : data
      re   = data.where(:retract => true).order_by(Sequel.desc(:tx)).to_a
      if re.empty?
        data.lazy
      else
        data.lazy.select do |tx|
          retracted = re.select { |r| r[:eid] == tx[:eid] && r[:attr] == tx[:attr] }
          if retracted.empty?
            true
          else
            if tx[:tx] > retracted.first[:tx]
              true
            else
              false
            end
          end
        end
      end
    end

    def tuples(*args)
      facts(*args).map do |fact|
        Hamster::Vector[fact[:eid], fact[:attr].to_sym, read_value(fact[:valType], fact[:val])]
      end
    end

    def each_fact(&block)
      facts.each(&block)
    end
    alias each each_fact

    def each_tx(&block)
      txs.each(&block)
    end

    def entity(id)
      eid = resolve_eid(id)
      return nil if eid.nil?
      @entities ||= {}
      @entities[eid] ||= begin
        e = Hash.new do |h, attr|
          xs = facts(eid, attr)
          if xs.count == 0
            nil
          elsif xs.count == 1
            r = xs.first
            h[attr.to_sym] = read_value(r[:valType], r[:val])
          else
            h[attr.to_sym] = vector(xs.map { |x| read_value(x[:valType], x[:val]) })
          end
        end
        e[ID_ATTR] = eid
        e
      end
    end
    alias [] entity

    def entity!(id)
      eid = resolve_eid(id)
      return nil if eid.nil?
      e = facts(eid).reduce({}) do |emap, r|
        key = r[:attr].to_sym
        val = 
          if r[:valType] == VALUE_TYPES[TREF]
            ref = r[:val].to_i
            # don't derefernce self references!!
            if ref == id then ref else entity!(ref) end
          else
            read_value(r[:valType], r[:val])
          end
        if r[:many] and collected = emap[key]
          emap.merge(key => collected.add(val))
        elsif r[:many]
          emap.merge(key => vector(val))
        else
          emap.merge(key => val)
        end
      end
      e[ID_ATTR] = eid
      @entities ||= {}
      @entities[eid] = e
      e
    end

    def query(q)
      if q.nil?
        facts.map do |fact|
          {:eid => fact[:eid], :attr => fact[:attr], :val => fact[:val]}
        end
      else
        Query.read_string(q).evaluate(self)
      end
    end

    def transact(facts)
      DB.transaction do
        t, tx = txdata
        res = process_facts(facts).map do |f|
          f = f.merge(:tx => tx, :t => t)
          @dataset.insert(f.to_h)
          f.merge(:valType => VALUE_TYPE_CODES[f[:valType]])
        end
        set(*res)
      end
    end

    def idents
      facts(nil, IDENT_ATTR).map { |r| r[:val] }
    end

    def to_s
      @name.to_s
    end

    private

    def process_hash_fact(fact)
      id = fact[ID_ATTR]
      fact =
        if fact.is_a? Hamster::Hash
          fact.delete(ID_ATTR)
        else
          fact.delete(ID_ATTR) && fact
        end
      fact.flat_map do |attr, val|
        if enum? val
          if val[0] == :ref
            [[ASSERT_IDENT, id, attr, val, :one]]
          elsif hash? val
            ref   = val[:'db.id'] or raise 'a :db.id is required'
            facts = process_hash_fact(val)
            facts << [ASSERT_IDENT, id, attr, [:ref, ref], :one]
          else
            val.flat_map do |x|
              if hash? x
                ref   = x[:'db.id'] or raise 'a :db.id is required'
                facts = process_hash_fact(x)
                facts << [ASSERT_IDENT, id, attr, [:ref, ref], :many]
              else
                [[ASSERT_IDENT, id, attr, x, :many]]
              end
            end
          end
        else
          [[ASSERT_IDENT, id, attr, val, :one]]
        end
      end
    end

    def process_facts(facts)
      facts_ = facts.flat_map do |fact|
        if indexed? fact
          raise TransactionError, 'an assertion/retraction should have 4 and only 4 elements' unless fact.count == 4
          unless fact[0] == ASSERT_IDENT or fact[0] == RETRACT_IDENT
            raise TransactionError, "first element should be either #{ASSERT_IDENT.inspect} or #{RETRACT_IDENT.inspect}"
          end
          [fact]
        elsif hash? fact
          process_hash_fact(fact)
        else
          raise TransactionError, 'a trasaction should be an array of array, vector, or hash elements'
        end
      end

      tempids = facts_.map { |x| x[1] }
        .select { |x| tempid?(x) }
        .map { |x| x[1] }
        .reduce({}) { |h, id| h.merge(id => Subway.dbid) }

      facts_.map do |fact|
        id = tempid?(fact[1]) ? tempids[fact[1][1]] : fact[1]
        raise "Can not process id: #{fact[1].inspect}" unless id
        val = ref?(fact[3]) && tempid?(fact[3][1]) ? [:ref, tempids[fact[3][1][1]]] : fact[3]
        process_fact fact[0], id, fact[2], val, fact[4]
      end
    end

    def process_fact(op, eid, attr, val, card)
      type = resolve_type(attr, val)
      retract = op == RETRACT_IDENT ? true : false
      hash(
        :retract => retract,
        :eid     => resolve_eid!(eid),
        :attr    => attr.to_s,
        :val     => write_value(type, val),
        :valType => type,
        :many    => card == :many ? true : false
      )
    end

    def ident_lookup ident
      if res = @dataset.where(:attr => IDENT_ATTR.to_s, :val => ident.to_s).first
        res[:eid];
      else
        nil
      end
    end

    def resolve_eid eid
      if eid.nil?
        raise DatabaseError, 'an entity id cannot be nil'
      elsif integer? eid 
        eid
      elsif numeral? eid
        eid.to_i
      elsif tempid? eid
        Subway.dbid
      else
        ident_lookup(eid)
      end
    end

    def txdata
      t = Time.now
      [t, (t.to_f * 1000000).round]
    end

    def resolve_eid! eid
      if ident = resolve_eid(eid)
        ident
      else
        raise DatabaseError, "could not resolve id: #{eid.inspect}"
      end
    end

    def attrtype(attr)
      if meta = entity!(attr)
        return VALUE_TYPES[(t = meta[VALUE_TYPE_ATTR]) && t.to_sym] || DEFAULT_VALUE_TYPE
      end
      nil
    end

    def valtype(val)
      sym =
        if    string?  val then TSTRING
        elsif symbol?  val then TSYMBOL
        elsif integer? val then TINTEGER
        elsif numeric? val then TDECIMAL
        elsif boolean? val then TBOOLEAN
        elsif instant? val then TINSTANT
        elsif uuid?    val then TUUID
        elsif uri?     val then TURI
        elsif ref?     val then TREF
        else
          TBLOB
        end
      VALUE_TYPES[sym]
    end

    def resolve_type(attr, val)
      return VALUE_TYPES[TREF] if ref?(val)
      atype = attrtype(attr)
      vtype = valtype(val)
      if atype.nil? or atype == vtype
        vtype
      else
        raise DatabaseError, "the value given does not match it's type constraint expected: #{VALUE_TYPE_CODES[atype]}, got: #{VALUE_TYPE_CODES[vtype]}"
      end
    end

    def write_value(tcode, value)
      @writer.send(type_method(tcode), value)
    end

    def read_value(tcode, value)
      @reader.send(type_method(tcode), value)
    end
  end
end
