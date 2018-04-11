require 'bundler/setup'
require 'sinatra'
require 'sinatra/url_for'
require 'sinatra/namespace'
require 'sequel'
require 'haml'
require 'uuidtools'
require 'securerandom'
require 'murmurhash3'
require 'uri'
require 'json'

require_relative '../lib/subway'
require_relative '../lib/subway/perl'
require_relative 'helpers'

DB = Sequel.connect("jdbc:sqlite:#{File.join(File.dirname(__FILE__), '..', 'db', 'subway.db')}")

#
# The web app
#

use Rack::MethodOverride

db = Subway::Database.make(:jobs)
if db.first.nil?
  db.transact(EDN.read(open(File.join(__dir__, '..', 'db', 'schema.edn'))))
end

error do
  case request.content_type
  when 'application/perl'
    perl error(env['sinatra.error'].message)
  when 'application/json'
    json error(env['sinatra.error'].message)
  else
    haml :error
  end
end

not_found do
  case request.content_type
  when 'application/perl'
    perl error('Not found')
  when 'application/json'
    json error('Not found')
  else
    haml :not_found
  end
end

helpers do
  include Subway
  include Subway::Helpers
end

get '/js/app.js' do
  coffee :client
end

get '/?' do
  redirect repos
end

namespace '/app' do
  get '/:app' do
    haml :app, :layout => false
  end
end

namespace '/admin' do
  # show repo list
  get '/repos' do
    @repos = repo_list
    haml :repos
  end

  # create repo
  post '/repos' do
    raise 'repo is required' unless params[:repo]
    make_repo(params[:repo])
    redirect repos
  end
  
  # list and query repo
  get '/repos/:repo' do
    @repo   = repo(params[:repo])
    @page   = (params[:p] || 1).to_i
    @psize  = (params[:page_size] || 15).to_i
    @query  = params[:q].nil? || params[:q].empty? ? nil : params[:q]
    @facts  = paginate(@repo.query(@query), @page, @psize)
    @fields = @facts.first ? @facts.first.keys : {}
    haml :repo
  end
  
  # add entity
  post '/repos/:repo/entity' do
    eid = add_entity(params[:repo])
    redirect entity(params[:repo], eid)
  end
  
  # view entity
  get '/repos/:repo/entity/:eid' do
    @repo = params[:repo]
    @entity_facts = repo(params[:repo]).facts(params[:eid])
    @entity_ident = @entity_facts.select { |f| f[:attr] == Subway::IDENT_ATTR }.first
    haml :entity
  end
  
  # assert fact to entity
  post '/repos/:repo/entity/:eid' do
    repo(params[:repo]).transact([[Subway::Database::ASSERT_IDENT, params[:eid], params[:attr], params[:val]]])
    redirect entity(params[:repo], params[:eid])
  end
  
  # retract fact to entity
  delete '/repos/:repo/entity/:eid' do
    repo(params[:repo]).transact([[Subway::Database::RETRACT_IDENT, params[:eid], params[:attr], params[:val]]])
    redirect entity(params[:repo], params[:eid])
  end
end

namespace '/api' do
  get '/?' do
    markdown :api, :layout_engine => :haml
  end

  # get repo list
  get '/repos' do
    repos = repo_list.map(&:to_s)
    case request.content_type
    when 'application/perl'
      perl success(repos)
    else
      json success(repos)
    end
  end
  
  # add repo
  post '/repos/:repo' do
    raise 'repo is required' unless params[:repo]
    make_repo(params[:repo])
    case request.content_type
    when 'application/perl'
      perl success(params[:repo])
    else
      json success(params[:repo])
    end
  end
  
  # list or query repo
  get '/repos/:repo' do
    repo   = repo(params[:repo])
    p      = (params[:p] || 1).to_i
    psize  = (params[:page_size] || 15).to_i
    q      = params[:q]
    facts  = paginate(repo.query(q), p, psize).force
    case request.content_type
    when 'application/perl'
      perl success(facts)
    else
      json success(facts)
    end
  end
  
  # get entity map
  get '/repos/:repo/entity/:eid' do
    entity = repo(params[:repo]).entity!(params[:eid])
    case request.content_type
    when 'application/perl'
      perl success(entity)
    else
      json success(entity)
    end
  end
  
  # get an event stream
  # formats Atom/RSS, others?
  get '/repos/:repo/transaction' do
    markdown :transact
  end

  # post a transaction
  post '/repos/:repo/transaction' do
    data = tx_data
    case request.content_type
    when 'application/perl'
      logger.info 'Perl client:'
      logger.info "Data: #{data.inspect}"
      res = repo(params[:repo]).transact(data)
      logger.info "Success: #{res.inspect}"
      perl success(res)
    else
      res = repo(params[:repo]).transact(data)
      json success(res)
    end
  end
  
  # get transaction meta data
  get '/repos/:repo/transaction/:tx' do
    tx = repo(params[:repo]).tx(params[:tx])
    case request.content_type
    when 'application/perl'
      perl success(tx)
    else
      json success(tx)
    end
  end
end
