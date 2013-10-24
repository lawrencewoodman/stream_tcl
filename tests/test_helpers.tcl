# Helper functions for the tests
package require stream

namespace eval TestHelpers {
}

# start and end are inclusive
proc TestHelpers::range {start end} {
  if {$start <= $end} {
    set nextNum [expr {$start + 1}]
    stream create $start [list TestHelpers::range $nextNum $end]
  } else {
    return [::list]
  }
}

proc TestHelpers::emptyStream {} {
  return [::list]
}
