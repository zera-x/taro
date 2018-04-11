NAME
====

Subway - A jobsub meta data repository

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

    curl -H "Content-type: application/json" "http://localhost:9292/repos" => {"status": "success", "data": []}

### Try It

[`/repos`](/api/repos)


POST - `/repos`
---------------

Creates a repository

### Parameters

- `repo` - required

### Example

    curl -H "Content-type: application/json" "http://localhost:9292/repos/heros" => {"status": "success", "data": ["heros"]}

or

    curl -H "Content-type: application/json" -XPOST "http://localhost:9292/repos" --data "repo=heros" => {"status": "success", "data": ["heros"]}


GET - `/repos/:repo`
--------------------

Provides an interface to page through or run queries on a repository

### Parameters

- `repo` - required
- `q` - optional
- `p` - optional
- `page_size` - optional

### Try It

[`/repos/heros`](/api/repos/heros)

### Example

    curl -H "Content-type: application/json" "http://localhost:9292/repos/heros"

Will return the first 15 repository facts

    curl -H "Content-type: application/json" "http://localhost:9292/repos/heros?page_size=20"

Will return the first 20

    curl -H "Content-type: application/json" "http://localhost:9292/repos/heros?p=2"

Will return results 15th through 30th entries

    curl -H "Content-type: application/json" "http://localhost:9292/repos/heros?q=[:find ?eid ?attr ?val :where [?eid ?attr ?val]]"

Will run the query and return the first 15 facts (NOTE: the query would have to be percent encoded)


POST - `/repos/:repo/transaction`
---------------------------------

Performs transactions (assertions and retractions) on the repository

### Parameters

JSON Data

### Example

    curl -H "Content-type: application/json" -XPOST "http://localhost:9292/repos/heros/transaction" \
      --data "[['db.assert', ['id', -1], 'hero.name', "Peter Parker"]]"

Temporary ID's like the `['id', -1]` tell the transactor to generate a new ID and when the index (`-1` in this case) matches
it tells the transactor to use the same generated ID.  For example:

    curl -H "Content-type: application/json" -XPOST "http://localhost:9292/repos/heros/transaction" \
      --data '[["db.assert", ["id", -1], "hero.name", "Peter Parker"]
               ["db.assert", ["id", -1], "hero.moniker", "Spiderman"]]'

Will produce and entity that looks like this:

    {"db.id": 1629339483,
     "hero.name": "Peter Parker",
     "hero.moniker": "Spiderman"}

.

So, a temporary ID value is a JSON array with an `"id"` tag and and index that is an integer below 0.

The transactor also provides a shortcut notation for assertions.  We could have added Peter Parker to the database like this:

    curl -H "Content-type: application/json" -XPOST "http://localhost:9292/repos/heros/transaction" \
      --data '[{"db.id": ["id", -1], "hero.name": "Peter Parker", "hero.moniker": "Spiderman"}]'

which is a little more compact especially as you add more and more attributes.
