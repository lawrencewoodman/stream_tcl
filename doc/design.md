Design Decisions
================

* Opted for `map`,`foldl`,etc to be able to take multiple streams rather than use `zip` when this is needed as more standard functions will be able to be passed directly to `map` and when multiple streams are needed this approach is much faster than using `zip`.  When only one stream is used the slow down is only marginal as the functions decide at the start if more than one stream is to be processed and then uses the most efficient method.  If streams really need zipping together, then it is easy to do with map:

    stream map list $stream1 $stream2 $stream3


* Decided to use `select` rather than `filter` as it can seem unclear when reading code with filters in, whether the filter is selecting or rejecting elements.
