The Data Access Interface for this library is a flexible way for the tree to
retrieve and cache information it needs.  This is important, because the use
case for this library is to provide hash trees for datasets *far* larger
than what can be reasonably stored in memory by Ruby objects, and
potentially in diverse and application-specific stores.  Therefore, it is
important that the interface between instances of `MerkleHashTree` and the
underlying list data is as flexible as possible.

The interface is designed so that an instance of `Array` *will* work, in the
minimal case, although it won't perform particularly well.  In order to
maximise performance, it is recommended that the optional caching methods
also be implemented, with the cache data stored either in memory, or in a
fast network-accessable cache such as memcached or Redis.


# Mandatory Methods

There are two mandatory methods which *must* be implemented by any object
which is passed in as the data object to a call to `MerkleHashTree.new`.
They might look familiar.

Both of these methods are called *very* frequently and repeatedly; it is
highly recommended that they perform their own caching of results if
retrieval from backing store is an expensive operation.  Caching is quite
easy in this system, because no value ever changes once it has been defined
(with the exception of `length`).


## `length`

This method returns the number of items in the list.  This number must be
monotonically increasing with each call -- that is, there must never be a
case where a call to `#length` on a given data object returns a
value less than that returned by a previous call to `#length` on that same
object.  Failure to observe this property will absolutely and with
guaranteed certainty lead to heartbreak.


## `[](n)`

This method returns the `n`th item in the list, indexed from zero.  All
values of `[](n)` for `0 <= n < length` must return an object which responds
to `to_s` correctly (the value of `to_s` is used as the value passed to the
hashing function which calculates the leaf hash value).

If `n` is greater than or equal to a value previously returned from a call
to `length` on the same object, it is permissible to either return `nil`,
raise `ArgumentError`, or do whatever you like -- if `MerkleHashTree` ever
does that, it's a big fat stinky bug in this library.

Once a call to this method with a given value of `n` has been made, *every*
future call for the same value of `n` MUST return an object whose `to_s`
method returns an identical string.  Failure to observe this requirement
will surely cause demons to fly out of your nose.


# Optional Methods

There are two optional methods which your DAI object may choose to
implement.  If you implement one, though, you must implement both.  They are
used to cache intermediate hashes within the tree nodes, and can
significantly improve performance on large trees, because it's a lot quicker
to retrieve a value from a database than it is to recalculate a few hundred
thousand SHA256 hashes.


## `mht_cache_set(key, value)`

This method takes a string `key` and a string `value`, and should store that
association somewhere convenient for later retrieval.  The return value is
ignored (although raising an exception is Just Not On).

For a given `key`, only one `value` will *ever* be passed (for a given DAI
object).  If this allows you to optimise some part of your cache
implementation, mazel tov.


## `mht_cache_get(key)`

This method takes a string `key` and returns either a string `value` or
`nil`.  If a string is returned, that string MUST be the value passed to a
previous call to `mht_cache_set` for the same `key`.

Since this is a caching interface, It is entirely permissible to return
`nil` to a call to `mht_cache_get` for a given key when a previous call for
the same key returned a string `value`.  The cache entry may well have
expired in the interim.  `MerkleHashTree` will *always* handle a call to
`mht_cache_get` returning `nil` (by recalculating any and all hashes
required to regenerate the value that has not been cached).

This method MAY be called with a given `key` without a previous call to
`mht_cache_set` being made for the same `key`, and your implementation must
handle that gracefully (by returning `nil`).


# Item Methods

The objects returned from calls to `[](n)` must implement a `to_s` method
that returns a string.  There is no requirement for the value returned by
`to_s` to be unique amongst all objects returned from `[](n)`, but I
certainly wouldn't recommend them all returning the same value (it would be
a very boring-looking hash tree).

To slightly improve performance, objects can also implement an accessor
method pair, `mht_leaf_hash` and `mht_leaf_hash=(s)`.  If available,
`mht_leaf_hash` will be called to determine the hash value of the object; if
this method returns `nil`, then the hash value will be calculated from the
string returned by `to_s`, and then cached in the object by calling
`mht_leaf_hash=(h)`.  It is not recommended that you try to be clever by
implementing a hashing scheme yourself in `mht_leaf_hash`; that way lies
madness.
