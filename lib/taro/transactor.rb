module Taro
  class Transactor
    def self.read_json(json)
      JSON.parse(json).map do |tx|
        if tx.is_a? Array
          id = tx[1].is_a?(Array) && tx[1][0] == 'id' ? [:id, tx[1][1]] : tx[1]
          [tx[0].to_sym, id, tx[2], tx[3]]
        elsif tx.is_a? Hash
          tx.reduce({}) do |h, kv|
            if kv[0] == 'db.id' and kv[1].is_a?(Array) and kv[1][0] == 'id'
              h.merge(:'db.id' => [:id, kv[1][1]])
            else
              h.merge(kv[0].to_sym => kv[1])
            end
          end
        else
          raise 'malformed data: a transaction should be an array with either array or object values'
        end
      end
    end

    def self.read_edn(db, edn)
      res = []
      EDN::Reader.new(edn).each do |datums|
        res.push(db.transact(datums))
      end
      res
    end
  end
end
