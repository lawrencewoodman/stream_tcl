# Helper functions for the tests
package require stream

namespace eval TestHelpers {
}

# start and end are inclusive
proc TestHelpers::range {start end} {
  set first {{stream} {
    lindex $stream 3
  }}

  set rest {{stream} {
    lassign $stream first rest isEmpty state
    stream create $first $rest $isEmpty [expr {$state + 1}]
  }}

  set isEmpty {{end stream} {
    lassign $stream first rest isEmpty state
    expr {$state > $end}
  }}
  return [stream create [list apply $first]           \
                        [list apply $rest]            \
                        [list apply $isEmpty $end]    \
                        $start]
}

proc TestHelpers::emptyStream {} {
  set first {{stream} {
    return
  }}

  set rest {{stream} {
    return $stream
  }}

  set isEmpty {{stream} {
    return 1
  }}

  return [stream create [list apply $first] \
                        [list apply $rest]  \
                        [list apply $isEmpty]]
}
