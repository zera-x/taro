module Subway
  class MalformedQueryException < Exception; end

  class Query
    class << self
      def read_string(str)
        analyze(EDN.read(str))
      end

      # [:find PROJECTION_VARS :where PREDICATES]
      def analyze(q)
        new(projection_vars(q), predicates(q))
      end

      private

      def intern_var(s)
        @vars ||= {}
        @vars[s] ||= Unific::Var.new(s.sub(/^\?/, ''))
      end

      def var?(v)
        v.is_a? EDN::Type::Symbol and ((s = v.to_s)[0] == '?' or s == '_')
      end

      def projection_vars(q)
        unless q.first == :find
          raise MalformedQueryException, 'query must begin with :find'
        end

        vars = q.drop(1).take_while { |x| x != :where }
        if vars.empty?
          raise MalformedQueryException, 'a query must have at least one projection variable'
        end

        Hamster::Vector.new(vars).map do |v|
          if var? v
            intern_var(v.to_s)
          else
            raise MalformedQueryException, 'projection vars should be symbols'
          end
        end
      end

      def predicates(q)
        preds = q.drop_while { |x| x != :where }.drop(1)
        if preds.empty? or preds.first.empty?
          raise MalformedQueryException, 'a query must have at least one predicate expression'
        end

        Hamster::Vector.new(preds).map do |p|
          Hamster::Vector.new(p).map do |v|
            if var? v
              s = v.to_s
              if s == '_'
                Unific::_
              else
                intern_var(s)
              end
            elsif v.is_a? EDN::Type::Symbol
              raise MalformedQueryException, 'variables must be the symbol _ or symbols that start with ?'
            else
              v
            end
          end
        end
      end
    end

    attr_reader :projection, :predicates

    def initialize(projection, predicates)
      @projection = projection
      @predicates = predicates
    end

    def join_vars
      predicates.map do |pred|
        Hamster::Set.new(pred.select { |x| x.is_a? Unific::Var })
      end
      .reduce(&:intersection)
    end

    def vector(*args)
      Hamster::Vector.new(args)
    end

    # unify
    #
    # [:find ?e ?k ?n :where [?e :student.name ?n] [?e :student.kind ?k]]
    #
    # [123456 :student.name "SZTEST"] => [Env[e => 123456, n => "SZTEST"], false]
    # ...
    # [123456 :student.kind "job"] => [false, Env[e => 123456, k => "job"]]
    # ...
    # [123456 :studnet.description "This is a test"] => [false, false]
    # ...
    def unify(db)
      predicates.reduce(nil) do |stream, pred|
        e = entity_ground?(pred)
        a = attr_ground?(pred)
        v = value_ground?(pred)
        if stream.nil?
          new_stream(db, e, a, v).map do |t|
            Unific::unify(t, pred)
          end
          .select { |x| x }
        else
          stream.flat_map do |env|
            new_stream(db, e, a, v).map do |t|
              env.unify(t, pred)
            end
            .select { |x| x }
          end
        end
      end
    end

    def project(env)
      projection.flat_map do |pvar|
        env.bindings.select { |x| pvar == x }.map do |bvar|
          Hamster::Vector[bvar.name, env[bvar]] 
        end
      end
    end

    def evaluate(db)
      unify(db).map do |env|
        project(env).reduce({}) do |pro, pair|
          pro.merge(pair[0].to_sym => pair[1])
        end
      end
    end

    private

    def new_stream(db, e, a, v)
      # attr ground
      if a and v
        db.tuples(nil, a, v)
      elsif a
        db.tuples(nil, a)
      elsif v
        db.tuples(nil, nil, v)
      else
        # nothing is ground
        db.tuples
      end
    end

    # returns true if entire predicate is ground (no variables)
    def ground?(pred)
      attr_ground?(pred) and value_ground?(pred) and entity_ground?(pred)
    end

    # returns true if attribute is ground
    def attr_ground?(pred)
      pred[1].is_a?(Unific::Var) ? nil : pred[1]
    end

    # returns true if entity is ground
    def entity_ground?(pred)
      pred[0].is_a?(Unific::Var) ? nil : pred[0]
    end

    # returns true if value is ground
    def value_ground?(pred)
      pred[2].is_a?(Unific::Var) ? nil : pred[2]
    end

    # for now we just support conjunctions
    def conjoin(values)
      values.all? { |v| !!v }
    end

    def var_positions
      predicates.map do |pred|
        projection.map do |pro|
          pred.index(pro)
        end
      end
    end

    def matches_join_val?(val, envs)
      envs.any? do |env|
        if env
          env.variables(val[0]) == val[1]
        else
          false
        end
      end
    end
  end
end
