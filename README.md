This gem contains an implementation of "Merkle Hash Trees" (MHT).
Specifically, it implements the variant described in
[RFC6962](http://tools.ietf.org/html/rfc6962), as the initial use-case for
this gem was for an implementation of a [Certificate
Transparency](http://www.certificate-transparency.org/) log server.

# Installation

Installation should be trivial, if you're using rubygems:

    gem install merkle-hash-tree

If you want to install directly from the git repo, run `rake install`.


# Usage

Using `MerkleHashTree` is relatively straightforward, although it does have
one or two intricacies.  Because MHTs typically deal with large volumes of
data, it isn't enough to just load a giant list of objects into memory and
go to town -- you'll run out of memory pretty quickly, and on a large tree
you'll likely burn a lot of CPU time computing hashes.  Instead, in order to
instantiate an MHT you must first construct an object that implements a
specific interface, which the MHT implementation then uses to interact with
your dataset.

## Basic Usage

For now, though, let's assume that you have such an object, named
`mht_data`, and we'll look at how to use the MHT.  (It might be useful to
understand [how MHT proofs
work](http://www.certificate-transparency.org/log-proofs-work) before you go
too deeply into this).

For starters, we'll create a new MHT:

    mht = MerkleHashTree.new(mht_data, Digest::SHA256)

The `MerkleHashTree` constructor takes exactly two arguments: an object that
implements the data access interface we'll talk about later, and a class (or
object) which implements the same `digest` method signature as the core
`Digest::Base` class.  Typically, this will simply be a `Digest` subclass,
such as `Digest::MD5`, `Digest::SHA1`, or (as in the example above)
`Digest::SHA256`.  This second argument is the way that the MHT calculates
hashes in the tree -- it simply calls the `#digest` method on whatever you
pass in as the second argument, passing in a string and expecting raw octets
out the other end.

Once we have our MHT object, we can start to do things with it.  For
example, we can get the hash of the "head" of the tree:

    mht.head   # => "<some long string of octets>"

You can also get the head of any subtree, by specifying the
first and last elements of the list to be covered by the subtree:

    mht.head(16, 20)   # => "<some more octets>"

Note that the beginning element must be a power of 2.

If you want to get the subtree from 0 to an arbitrary element in the list,
you can just specify the last element:

    mht.head(42)   # => "<some other long string of octets>"
    # equivalent to
    mht.head(0, 42)

We can also ask for a "consistency proof" between any two subtrees:

    mht.consistency_proof(42, 69)   # => ["<hash>", "<hash>", ... ]

If we want a consistency proof between a subtree and the current head, we
can drop the second parameter:

    mht.consistency_proof(42)   # => ["<hash>", "<hash>", ... ]

I'm not going to describe Merkle consistency proofs here; the Internet does
a far better job than I ever will.  The return value of `#consistency_proof`
is simply an array of the hashes that are required by a client to prove that
the smaller subtree is, indeed, a subtree of the larger one (and nothing
dodgy has gone on behind the scenes).  [RFC6962,
s2.1.2](http://tools.ietf.org/html/rfc6962#section-2.1.2) has all the gory
details of how to calculate it and how to use the result.

There are also such things as "audit proofs" (again, I'm not going to
explain them here), which you get by specifying a single leaf number and a
subtree ID:

    mht.audit_proof(13, 42)   # => ["<hash>", "<hash>", ... ]

In this example, the audit proof will return a list of hashes, starting from
the leaf node's sibling and working up towards the root node for a hash tree
containing 42 elements, that demonstrate that leaf 13 is in the tree and
hasn't been removed or altered.

You can also drop the second argument, in which case you get an audit proof
for the tree that represents the entire list as it currently exists:

    mht.audit_proof(13)   # => ["<hash>", "<hash>", ... ]

And that's it!  There really isn't much you can do from the outside.  All
the fun happens inside.


## The Data Access Interface

Rather than trying to work with an entire dataset in memory,
`MerkleHashTree` is capable of working with a dataset far larger than what
could fit in memory, by using a data access object to fetch items and cache
intermediate results (the hashes of nodes in the tree).  To do this, though,
a fair number of methods need to be implemented.

How you implement them is up to you -- you could query a backend database,
or just make up data as you felt like it.  In the minimal case, you *can*
pass in an instance of Array, although I doubt you'll enjoy the performance
on any but the smallest possible hash tree.

The complete interface definition is given in `doc/DAI.md`, for those who
wish to implement their own interface.  Essentially, you *must* to implement
`[](n)`, which returns the `n`th entry in the (zero-indexed) list, as well
as `length`, which returns the current size of the list.  You can also
implement `mht_cache_set(key, val)` and `mht_cache_get(key)`, which set and
get entries in the cache of node values.  If you don't implement these, then
`MerkleHashTree` will need to recalculate every hash in the tree repeatedly
for most every operation -- which will be *very* slow for anything other
than the most trivial result.

As I said before, you *can* just use Array, if you want to, which could look
something like this:

    a = Array.new
    mht = MerkleHashTree.new(a, Digest::MD5)

    a << 'a'
    a << 'b'
    a << 'c'
    a << 'd'
    a << 'e'

    mht.head   # => "O\xA2\x03\x12\xF6\x0F\xFBtU\x95GY\xE53\x17\x8D"


## Further Info

In a reversal of standard operating procedure, I heavily document all the
methods and interfaces I write.  You can get complete API documentation by
using `ri` (or a descendent thereof), or via your web-based rdoc browser of
choice.
