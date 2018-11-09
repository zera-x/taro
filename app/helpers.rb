require 'cgi'

module Taro
  module Helpers
    def repos(id=nil)
      if id
        url_for "/admin/repos/#{id}"
      else
        url_for '/admin/repos'
      end
    end

    def entity(repo, id=nil)
      if id
        url_for "/admin/repos/#{repo}/entity/#{id}"
      else
        url_for "/admin/repos/#{repo}/entity"
      end
    end

    def api_entity(repo, id=nil)
      if id
        url_for "/api/repos/#{repo}/entity/#{id}"
      else
        url_for "/api/repos/#{repo}/entity"
      end
    end

    def api_repos(id=nil)
      if id
        url_for "/api/repos/#{id}"
      else
        url_for '/api/repos'
      end
    end

    SYMBOLS = {
      '\\.' => '__DOT__',
      '\\/' => '__SLASH__',
      '\\:'   => '__COLON__',
      '\\?'   => '__QUEST__',
      '\\!'   => '__BANG__'
    }

    def encode_punct(val)
      s = val.to_s
      SYMBOLS.each do |k, v|
        s = s.gsub(/#{k}/, v)
      end
      s
    end

    def repo(name)
      Database.get(CONNECTION, name)
    end

    def add_entity(name)
      Taro.dbid
    end

    def paginate(enum, p, psize)
      enum.drop((p - 1) * psize).take(psize)
    end

    def make_repo(name)
      Database.make(CONNECTION, name)
    end

    def repo_list
      Database.all(CONNECTION)
    end

    def u(s)
      URI.escape(s).gsub('?', '%3F')
    end

    def h(s)
      CGI.escapeHTML(s)
    end

    def format(val)
      if val.nil?
        'nil'
      elsif val.is_a? URI
        "<a target=\"__taro\" href=\"#{val.to_s}\">#{val.to_s}</a>"
      elsif val.is_a? FalseClass
        'no'
      elsif val.is_a? TrueClass
        'yes'
      else
        val.to_s
      end
    end

    def perl(val)
      val.to_perl
    end
    
    def json(val)
      content_type 'application/json'
      JSON.pretty_generate(val)
    end

    def pdn_data
      request.body.rewind
      PDN.parse(request.body.read)
    end

    def json_data
      request.body.rewind
      str = request.body.read
      logger.info "JSON raw-string: #{str.inspect}"
      JSON.parse(str)
    end

    def tx_data
      request.body.rewind
      str = request.body.read
      logger.info "JSON raw-string: #{str.inspect}"
      Transactor.read_json(str)
    end

    def error(msg)
      {:status => 'error', :message => msg}
    end

    def success(data)
      {:status => 'success', :data => data}
    end

    def data
      request.body.rewind
      URI.decode_www_form(request.body.read).reduce({}) do |h, kv|
        h.merge(kv[0].to_sym => kv[1])
      end
    end

    def next_page(page, q)
      if q.nil?
        "<li><a href=\"?p=#{page + 1}\">&raquo;</a></li>"
      else
        "<li><a href=\"?p=#{page + 1}&q=#{u q}\">&raquo;</a></li>"
      end
    end

    def prev_page(page, q)
      if page == 1
        '<li><a href="#">&laquo;</a></li>'
      elsif q.nil?
        "<li><a href=\"?p=#{page - 1}\">&laquo;</a></li>"
      else
        "<li><a href=\"?p=#{page - 1}&q=#{u q}\">&laquo;</a></li>"
      end
    end
  end
end

