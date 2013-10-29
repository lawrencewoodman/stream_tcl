package require tcltest
namespace import tcltest::*
package require struct::list

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set ModuleDir [file normalize [file join $ThisScriptDir ..]]
::tcl::tm::path add $ModuleDir

source [file join $ThisScriptDir test_helpers.tcl]

package require stream


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


test map-1 {Checks that map processes the correct values} \
-setup {
  set thousand 1000
  set endNum 10
  set expectedList {}

  for {set i 0} {$i <= $endNum} {incr i} {
    lappend expectedList [expr {$i + $thousand}]
  }

  set seq [TestHelpers::range 0 $endNum]

  proc mapper {num item} {expr {$item + $num}}

} -body {
  set mappedList [stream map [list mapper $thousand] $seq]
  set aList [stream toList $mappedList]
  ::struct::list equal $aList $expectedList
} -result 1

test map-2 {Checks that map takes multiple streams} \
-setup {
  set seq1 [TestHelpers::range 0 5]
  set seq2 [TestHelpers::range 10 15]

  proc mapper {a b} {
    expr {$a + $b}
  }

} -body {
  set mappedList [stream map mapper $seq1 $seq2]
  set aList [stream toList $mappedList]
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
  set aList [stream toList $mappedList]
} -result {10 12 14 16 18 20}

test take-1 {Checks that take outputs empty list if no elements requested} \
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


test zip-1 {Checks zip combines multiple streams} \
-setup {
  set endNum 10
  set expectedList {}

  for {set i 0} {$i <= $endNum} {incr i} {
    lappend expectedList [list [expr {$i}]       \
                               [expr {$i + 1}]   \
                               [expr {$i + 2}]]
  }

  set seq1 [TestHelpers::range 0 $endNum]
  set seq2 [TestHelpers::range 1 [expr {$endNum + 1}]]
  set seq3 [TestHelpers::range 2 [expr {$endNum + 2}]]
} -body {
  set zippedList [stream zip $seq1 $seq2 $seq3]
  set aList [stream toList $zippedList]
  ::struct::list equal $aList $expectedList
} -result 1


test zip-2 {Checks zip stops combining at shortest stream} \
-setup {
  set endNum 10
  set expectedList {}

  for {set i 0} {$i <= $endNum} {incr i} {
    lappend expectedList [list [expr {$i + 1}]   \
                               [expr {$i}]       \
                               [expr {$i + 2}]]
  }

  set seq1 [TestHelpers::range 1 [expr {$endNum + 100}]]
  set seq2 [TestHelpers::range 0 $endNum]
  set seq3 [TestHelpers::range 2 [expr {$endNum + 200}]]
} -body {
  set zippedList [stream zip $seq1 $seq2 $seq3]
  set aList [stream toList $zippedList]
  ::struct::list equal $aList $expectedList
} -result 1


cleanupTests
