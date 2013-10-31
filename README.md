stream
======
A Tcl module providing streams.

Streams provide a useful abstraction to process large amounts of data without having to hold it all in memory.  This allows you to process the streams by creating new streams with various functions such as `map`, `select`, etc.  You can then run a function such as `foldl` on the created streams to action the processing which until then and only been specified.

This implementation is based on streams in [SICP](http://mitpress.mit.edu/sicp/) with the functions operating on them inspired by those in [Racket](http://racket-lang.org).

Module Usage
------------
A stream consists of the first element of that stream followed by a function that returns a stream consisting of the rest of the stream.  This is created using the `stream create` command.

To create an infinite stream consisting of the set of natural numbers you could do the following:

    package require stream

    proc naturals {{start 0}} {
      set nextNum [expr {$start + 1}]
      stream create $start [list naturals $nextNum]
    }

If you then wanted to add `1000` to the natural numbers and get the sum of the first 10 even numbers:

    namespace import ::tcl::mathop::+

    proc addThousand {num} {
      expr {$num + 1000}
    }

    proc isEven {num} {
      expr {$num % 2 == 0}
    }

    set thousands [stream map addThousand [naturals]]
    set evenThousands [stream select isEven $thousands]
    set tenThousands [stream take 10 $evenThousands]
    set sum [stream foldl + 0 $tenThousands]
    puts "sum: $sum"

In the above each stream command is building upon other streams to describe and create new streams.  The elements of the streams aren't _properly_ processed until `foldl` is run to sum them, hence the reason that `map` is able to return even though it is operating on an infinite stream.  The reason that we say '_properly_ processed' above is that `select` will process each element until it finds the first match, however in the above example it finds a match on the first element.

Commands
--------

**stream create** _first_ _restCmdPrefix_<br />
Create a stream where _first_ specifies the first element of the stream and _restCmdPrefix_ is a command that returns a stream consisting of the rest of the stream.

**stream first** _stream_<br />
Returns the first element of the _stream_.

**stream foldl** _cmdPrefix_ _initalValue_ _stream_ _?stream ..?_<br />
Passes _initialValue_ to _cmdPrefix_ followed by the first element of each _stream_.  The result of _cmdPrefix_ being run with this is then passed to it again instead of the _initialValue_ and the next element of each _stream_ is passed along with it.  This process is repeated until one of the streams is empty, at which point the last return value of _cmdPrefix_ is returned by `foldl`.  If one of the _stream_s is empty to start with then _initialValue_ is returned.

**stream foreach** _varName_ _stream_ _?varName stream ..?_ _body_<br />
Evaluates _body_ with each element of the _stream_s accessed by their associated _varName_ variable.  The command returns the result of the last value returned in _body_.  Processing of _stream_s finishes when the first _stream_ is empty.

**stream isEmpty** _stream_<br />
Returns whether the _stream_ is empty.

**stream map** _cmdPrefix_ _stream_ _?stream ..?_<br />
Creates a new stream where each element of _stream_ has _cmdPrefix_ applied to it.

**stream rest** _stream_<br />
Returns a stream consisting of the current _stream_ less the first element.

**stream select** _cmdPrefix_ _stream_<br />
Creates a new stream that contains the elements of _stream_ for which the predicate _cmdPrefix_ returns true when passed those elements.  If the first element isn't matched then the stream is processed until a matching element is found or the stream is empty.

**stream take** _num_ _stream_<br />
Creates a new stream consisting of the first _num_ elements of _stream_.  If _stream_ has less then _num_ elements then as many as possible will be taken.

**stream toList** _stream_<br />
Returns the stream as a list.

Requirements
------------
*  Tcl 8.5+

Installation
------------
To install the module you can use the [installmodule.tcl](https://github.com/LawrenceWoodman/installmodule_tcl) script or if you want to manually copy the file `stream-*.tm` to a specific location that Tcl expects to find modules.  This would typically be something like:

    /usr/share/tcltk/tcl8.6/tcl8/

To find out what directories are searched for modules, start `tclsh` and enter:

    foreach dir [split [::tcl::tm::path list]] {puts $dir}

or from the command line:

    $ echo "foreach dir [split [::tcl::tm::path list]] {puts \$dir}" | tclsh

Testing
-------
There is a testsuite in `tests/`.  To run it:

    $ tclsh tests/stream.test.tcl

Contributions
-------------
If you want to improve this module make a pull request to the [repo](https://github.com/LawrenceWoodman/stream_tcl) on github.  Please put any pull requests in a separate branch to ease integration and add a test to prove that it works.

Licence
-------
Copyright (C) 2013, Lawrence Woodman <lwoodman@vlifesystems.com>

This software is licensed under an MIT Licence.  Please see the file, LICENCE.md, for details.
