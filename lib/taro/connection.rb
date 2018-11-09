require 'forwardable'

module Taro
  class Connection
    extend Forwardable

    def_delegators :@db, :create_table, :create_table?, :[], :transaction, :tables

    def initialize(config)
      @db = Sequel.connect(config)
    end
  end
end
