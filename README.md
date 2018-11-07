NAME
====

Taro - A queryable data store

Hypermedia API
==============

Content Types
-------------

- JSON - default
- XML  - `Content-type: application/xml`
- Atom - `Content-type: application/atom+xml` (for updates stream)
- Perl - `Content-type: application/perl`

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

    curl -H "Content-type: application/json" "http://localhost:9292/repos/test" => ["meta", "OPIE", "student", "test"]


GET - `/repos/:repo`
--------------------

Provides an interface to page through or run queries on a repository

### Parameters

- `repo` - required
- `q` - optional
- `p` - optional
- `page_size` - optional

### Example

    curl -H "Content-type: application/json" "http://localhost:9292/repos/student"

Will return the first 15 repository facts

    curl -H "Content-type: application/json" "http://localhost:9292/repos/student?page_size=20"

Will return the first 20

    curl -H "Content-type: application/json" "http://localhost:9292/repos/student?p=2"

Will return results 15th through 30th entries

    curl -H "Content-type: application/json" "http://localhost:9292/repos/student?q=[:find ?eid ?attr ?val :where [?eid ?attr ?val]]"

Will run the query and return the first 15 facts (NOTE: the query would have to be percent encoded)

POST - `/repos/:repo/entity`
----------------------------

Creates an entity in the named repository

### Parameters

- `repo` - required

### Example

    curl -H "Content-type: application/json" "http://localhost:9292/repos" => ["meta", "OPIE", "test"]
