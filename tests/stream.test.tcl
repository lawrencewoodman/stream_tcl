package require tcltest
namespace import tcltest::*
package require struct::list

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set ModuleDir [file normalize [file join $ThisScriptDir ..]]
::tcl::tm::path add $ModuleDir

source [file join $ThisScriptDir test_helpers.tcl]

package require stream

test first-1 {Checks outputs the first element of a stream} \
-setup {
  set seq [TestHelpers::range 3 15]
} -body {
  stream first $seq
} -result 3


test foldl-1 {Checks foldl outputs the accumulated value for non-empty list} \
-setup {
  set endNum 10
  set expectedSum [expr {$endNum*($endNum+1)/2+3}]
  set seq [TestHelpers::range 1 $endNum]

  proc add {a b} {expr {$a + $b}}
} -body {
  set listSum [stream foldl add 3 $seq]
  expr {$listSum == $expectedSum}
} -result 1

test foldl-2 {Checks foldl outputs the initial value for an empty list} \
-setup {
  set emptySeq [TestHelpers::emptyStream]
  proc add {a b} {expr {$a + $b}}

} -body {
  stream foldl add 3 $emptySeq
} -result 3

test foldl-3 {Checks process multiple streams} \
-setup {
  set seq1 [TestHelpers::range 1 5]
  set seq2 [TestHelpers::range 2 6]
  proc sumMul {runningTotal a b} {
    expr {$runningTotal + ($a * $b)}
  }
} -body {
  stream foldl sumMul 3 $seq1 $seq2
} -result 73

test foldl-4 {Checks that stops at end of shortest stream when using \
multiple streams} \
-setup {
  set seq1 [TestHelpers::range 1 5]
  set seq2 [TestHelpers::range 2 15]
  proc sumMul {runningTotal a b} {
    expr {$runningTotal + ($a * $b)}
  }
} -body {
  stream foldl sumMul 3 $seq1 $seq2
} -result 73

test foldl-5 {Checks that runs cmdPrefix at correct level with a single stream} \
-setup {
  namespace eval fold-5Test {
    set seq1 [TestHelpers::range 1 5]
    proc sum {ns runningTotal a} {
      foreach n $ns {
        incr runningTotal $n
      }
      expr {$runningTotal + $a}
    }
  }
} -body {
  namespace eval fold-5Test {
    stream foldl [list sum {5 6}] 3 $seq1
  }
} -cleanup {
  namespace delete fold-5Test
} -result 73


test foldl-6 {Checks that runs cmdPrefix at correct level with multiple streams} \
-setup {
  namespace eval fold-6Test {
    set seq1 [TestHelpers::range 1 5]
    set seq2 [TestHelpers::range 11 15]
    proc sum {ns runningTotal a b} {
      foreach n $ns {
        incr runningTotal $n
      }
      expr {$runningTotal + $a + $b}
    }
  }
} -body {
  namespace eval fold-6Test {
    stream foldl [list sum {5 6}] 3 $seq1 $seq2
  }
} -cleanup {
  namespace delete fold-6Test
} -result 138


test foreach-1 {Checks that body is run for each value in stream} \
-setup {
  set seq [TestHelpers::range 1 5]
} -body {
  set total 0
  stream foreach item $seq {
    incr total $item
  }
  set total
} -result 15

test foreach-2 {Checks that returns result of last execution in body} \
-setup {
  set seq [TestHelpers::range 1 5]
} -body {
  stream foreach item $seq {
    expr {7 + $item}
  }
} -result 12

test foreach-3 {Checks that processes multiple streams} \
-setup {
  set seq1 [TestHelpers::range 1 5]
  set seq2 [TestHelpers::range 2 6]
} -body {
  set total 0
  stream foreach itemA $seq1 itemB $seq2 {
    incr total [expr {$itemA + $itemB}]
  }
  set total
} -result 35

test foreach-4 {Checks that returns result of last execution in body, when \
processing multiple streams} \
-setup {
  set seq1 [TestHelpers::range 1 5]
  set seq2 [TestHelpers::range 2 6]
} -body {
  stream foreach itemA $seq1 itemB $seq2 {
    expr {$itemA + $itemB}
  }
} -result 11


test fromList-1 {Checks that values are represented in stream} \
-setup {
  set aList {7 9 4 1 2 4 5 10 hello}
} -body {
  set aStream [stream fromList $aList]
  stream toList $aStream
} -result {7 9 4 1 2 4 5 10 hello}


test isEmpty-1 {Checks that returns false if list not empty} \
-setup {
  set seq [TestHelpers::range 1 1]
} -body {
  stream isEmpty $seq
} -result 0

test isEmpty-2 {Checks that returns true if list empty} \
-setup {
  set seq [TestHelpers::emptyStream]
} -body {
  stream isEmpty $seq
} -result 1


test map-1 {Checks that map processes the correct values} \
-setup {
  set thousand 1000
  set seq [TestHelpers::range 0 $endNum]
  proc mapper {num item} {expr {$item + $num}}
} -body {
  set mappedList [stream map [list mapper $thousand] $seq]
  stream toList $mappedList
} -result {1000 1001 1002 1003 1004 1005 1006 1007 1008 1009 1010}

test map-2 {Checks that map takes multiple streams} \
-setup {
  set seq1 [TestHelpers::range 0 5]
  set seq2 [TestHelpers::range 10 15]

  proc mapper {a b} {
    expr {$a + $b}
  }

} -body {
  set mappedList [stream map mapper $seq1 $seq2]
  stream toList $mappedList
} -result {10 12 14 16 18 20}

test map-3 {Checks that map stops at end of shortest stream} \
-setup {
  set seq1 [TestHelpers::range 0 5]
  set seq2 [TestHelpers::range 10 20]

  proc mapper {a b} {
    expr {$a + $b}
  }

} -body {
  set mappedList [stream map mapper $seq1 $seq2]
  stream toList $mappedList
} -result {10 12 14 16 18 20}


test rest-1 {Checks that returns the rest of the list} \
-setup {
  set seq [TestHelpers::range 3 8]
} -body {
  stream toList [stream rest $seq]
} -result {4 5 6 7 8}

test rest-2 {Checks that returns an empty list if no elements left} \
-setup {
  set seq [TestHelpers::range 1 1]
} -body {
  list [stream first $seq] [stream rest $seq]
} -result {1 {}}


test select-1 {Checks that outputs an empty stream if no matching elements} \
-setup {
  set seq [TestHelpers::range 0 10]
  set gt10 {{el} {expr {$el > 10}}}
} -body {
  stream toList [stream select [list apply $gt10] $seq]
} -result {}

test select-2 {Checks that outputs elements for which the predicate matches} \
-setup {
  set seq [TestHelpers::range 0 10]
  set divByThree {{el} {expr {$el % 3 == 0}}}
} -body {
  stream toList [stream select [list apply $divByThree] $seq]
} -result {0 3 6 9}


test take-1 {Checks that take outputs empty stream if no elements requested} \
-setup {
  set endNum 10
  set seq [TestHelpers::range 0 $endNum]

} -body {
  stream toList [stream take 0 $seq]
} -result {}

test take-2 {Checks that take outputs the correct number of elements} \
-setup {
  set endNum 10
  set seq [TestHelpers::range 0 $endNum]

} -body {
  stream toList [stream take 5 $seq]
} -result {0 1 2 3 4}

test take-3 {Checks that take outputs as many elements as it can if more \
requested than available} \
-setup {
  set endNum 10
  set seq [TestHelpers::range 0 $endNum]
} -body {
  stream toList [stream take 15 $seq]
} -result {0 1 2 3 4 5 6 7 8 9 10}

test toList-1 {Checks that toList outputs the stream to a list} \
-setup {
  set endNum 10
  set seq [TestHelpers::range 0 $endNum]
} -body {
  stream toList $seq
} -result {0 1 2 3 4 5 6 7 8 9 10}


cleanupTests
