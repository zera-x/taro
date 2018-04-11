TODO
====

URGENT
======

- [x] Server needs to be able to generate tempid's can do so by having the client pass a tagged value
- [x] Bulk assertions

REQUIRED
========

BUGS
----

- [ ] Query "current" database should eliminate older assertions of the same attribute (See Database#facts)

UI
--

- [x] Pagination is broken in repo view
- [ ] "Add Repo" is broken
- [x] "Update" and "Remove" are broken
- [ ] What should the client facing part of the UI contain?
  - App Server (JS based applications)
  - Reports
  - Analysis
  - Fulltext querying

Internals
---------

- Type coersion (when attribute meta data is present)
- Extensible event system
- Database functions (integrate with Event system, and Transactor)
- Extensible extension system (any JVM language, make sure JS, Java, and Groovy are well supported)
- IPC? (Pi calculus symatics)
- Server-side REPL for transactions and queries?

Type System
-----------

- String
  - DateTime (ISO)
  - Symbol
  - Keyword
- Number
  - Integer
    - Timestamp (Unix)
  - Double
- Boolean
- Array
  - List
- Object
  - Map (default)
  - Set
  - Ref (extention type)

- Use transit for Hypermedia communication
- Workout UI elements for admin interface

API
---

- [x] Perl libary
- [ ] CLI Application for use in shell scripts (based on Perl library)
- [ ] Java library
- [ ] XML support for API
- [ ] CSV support
- [ ] Excel (see https://github.com/kameeoze/jruby-poi)
- [ ] integration tests

INTEGRATIONS
------------

- [ ] Integrate with CI process
  - [ ] investigate Jenkins integrations

NICE TO HAVE
============

- Git integration?

- Atom/RSS feeds of changes on repos and entities

- When adding attributes to entity, attribute field an autolookup
  field populated by ident's in "meta", the user should be able to add
  any text also.  When an attribute is selected with meta data, an appropriate
  input field should be displayed based on the attributes type.

- Fulltext search, add meta attribute db.fulltext, build index with Apache Lucene
  (see https://github.com/davidx/jruby-lucene)

- Late bound data types, when a meta attribute is added a new thread starts and asserts
  new attribute values with that type.

- Add attribute indexing to speed up queries (see https://github.com/tyler/trie)
  - Don't think this kind of indexing will be necessary we could do this simply by
    at start up creating a thread (the transactor) that (lazily) builds an in memory SQLite DB
    that represents the DB's "current" it will also be responsible for writing to the DB and updating "current"
    an Atom from concurrent-ruby will work well for this.
    - We'll need a hash value to test equality the last tx id will do nicely for this purpose
