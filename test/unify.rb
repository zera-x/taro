require_relative '../app/subway'

db = Subway::Database[:jobs]
res = db.query('[:find ?e ?name ?ident :where [?e :student.name ?name] [?e :db.ident ?ident]]')
res.to_a