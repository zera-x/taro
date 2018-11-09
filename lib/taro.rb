require 'bundler/setup'
require 'sinatra'
require 'sinatra/url_for'
require 'sequel'
require 'haml'
require 'uuidtools'
require 'securerandom'
require 'murmurhash3'
require 'uri'
require 'hamster'
require 'edn'
require 'unific'

require_relative 'taro/core_ext'
require_relative 'taro/core'
require_relative 'taro/types'
require_relative 'taro/query'
require_relative 'taro/connection'
require_relative 'taro/db'

module Taro
  VERSION = '0.1.0'.freeze

  def self.uuid
    UUIDTools::UUID.random_create
  end

  def self.dbid
    MurmurHash3::V32.fmix(SecureRandom.hex(4).hex)
  end

  def self.tempid(i=nil)
    i =
      if i.nil?
        @currentid = if @currentid then @currentid - 1 else -1 end
      end
    [:id, i]
  end
end
