require_relative '../../app/subway.rb'
require 'json'
require 'csv'

#db = Subway::Database[:jobs]
#jobs = db.query('[:find ?e ?name :where [?e :job.name ?name]]').force
#print jobs.to_json
#print names.to_json
#files = JSON.parse(IO.read(ARGV[0]))
#names = files.map { |x| x['name'] }.uniq
#jobs = names.map do |name|
#  {:'db.id'     => Subway.tempid,
#   :'job.name'  => name,
#   :'job.files' => files.select { |x| x['name'] == name }.map { |x| [:ref, x['e']] }}
#end

class CSV::Row
  def to_json(*args)
    "{#{self.map { |x| "#{x[0].to_json}:#{x[1].to_json}" }.join(',')}}"
  end
end

def student_to_entity(s)
  e = {:'db.id' => Subway.tempid}
  s.reduce(e) do |emap, kv|
    if kv[1]
      emap.merge(:"student.#{kv[0]}" => kv[1])
    else
      emap
    end
  end
end

jobs = JSON.parse(IO.read(ARGV[0]))
students = CSV.table(ARGV[1])
jobs_ = jobs.flat_map do |job|
  students.select { |s| s[:name] =~ /#{job['name']}/i }.map { |s| student_to_entity(s.to_hash).merge(:'student.job' => [:ref, job['e']]) }
end
print jobs_.to_json
