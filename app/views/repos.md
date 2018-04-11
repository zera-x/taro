GET - `/repos`
--------------

Returns a list of repositories

### Parameters

None

### Example

    curl -H "Content-type: application/json" "http://localhost:9292/repos" => ["meta", "OPIE", "student"]


POST - `/repos`
---------------

Creates a repository

### Parameters

- `repo` - required

### Example

    curl -H "Content-type: application/json" -XPOST "http://localhost:9292/repos/test" => ["meta", "OPIE", "student", "test"]

or

    curl -H "Content-type: application/json" -XPOST "http://localhost:9292/repos" --data "repo=test" => ["meta", "OPIE", "student", "test"]
