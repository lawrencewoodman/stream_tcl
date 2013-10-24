package require tcltest
namespace import tcltest::*
package require struct::list

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set ModuleDir [file normalize [file join $ThisScriptDir ..]]
::tcl::tm::path add $ModuleDir

source [file join $ThisScriptDir test_helpers.tcl]

package require stream

test map-1 {Checks that map processes the correct values} \
-setup {
  set thousand 1000
  set endNum 10
  set expectedList {}

  for {set i 0} {$i <= $endNum} {incr i} {
    lappend expectedList [expr {$i + $thousand}]
  }

  set first {{stream} {
    lassign $stream first rest isEmpty state
    return $state
  }}

  set rest {{stream} {
    lassign $stream first rest isEmpty state
    stream create $first $rest $isEmpty [expr {$state + 1}]
  }}

  set isEmpty {{listSize stream} {
    lassign $stream first rest isEmpty state
    expr {$state >= $listSize}
  }}

  set seq [TestHelpers::range 0 $endNum]

  proc mapper {num item} {expr {$item + $num}}

} -body {
  set mappedList [stream map [list mapper $thousand] $seq]
  set aList [stream toList $mappedList]
  ::struct::list equal $aList $expectedList
} -result 1

test foldl-1 {Checks foldl outputs the accumulated value for non-empty list} \
-setup {
  set thousand 1000
  set endNum 10
  set expectedSum [expr {$endNum*($endNum+1)/2+3}]
  set seq [TestHelpers::range 1 $endNum]

  proc add {a b} {expr {$a + $b}}
  proc mapper {num item} {expr {$item + $num}}
} -body {
  set listSum [stream foldl add 3 $seq]
  expr {$listSum == $expectedSum}
} -result 1

test foldl-2 {Checks foldl outputs the initial value for an empty list} \
-setup {
  set thousand 1000
  set listSize 0

  set expectedSum 3

  set emptySeq [TestHelpers::emptyStream]
  proc add {a b} {expr {$a + $b}}
  proc mapper {num item} {expr {$item + $num}}

} -body {
  set listSum [stream foldl add 3 $emptySeq]
  expr {$listSum == $expectedSum}
} -result 1

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
