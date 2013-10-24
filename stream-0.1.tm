# A stream ensemble
#
# Copyright (c) 2013 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

package require Tcl 8.6

namespace eval stream {
  namespace export {[a-z]*}
  namespace ensemble create
}

proc stream::create {first rest} {
  return [list $first $rest]
}

proc stream::first {stream} {
  lassign $stream first
  $first
}

proc stream::rest {stream} {
  set rest [lindex $stream 1]
  {*}$rest
}

proc stream::isEmpty {stream} {
  expr {[llength $stream] == 0}
}

proc stream::map {cmdPrefix stream} {
  lassign $stream first rest
  if {[isEmpty $stream]} {
    return $stream
  } else {
    create [{*}$cmdPrefix $first] [list stream map $cmdPrefix [{*}$rest]]
  }
}

proc stream::zip {args} {
  set firsts [::list]
  set restStreams [::list]
  foreach stream $args {
    if {[isEmpty $stream]} {
      return $stream
    }
    lassign $stream first rest
    lappend firsts $first
    lappend restStreams [{*}$rest]
  }
  return [create $firsts [list stream zip {*}$restStreams]]
}

proc stream::foldl {cmdPrefix initialValue stream} {
  set acc $initialValue
  while {![isEmpty $stream]} {
    lassign $stream first rest
    set acc [{*}$cmdPrefix $acc $first]
    set stream [{*}$rest]
  }
  return $acc
}

proc stream::toList {stream} {
  set res [::list]
  while {![isEmpty $stream]} {
    lassign $stream first rest
    lappend res $first
    set stream [{*}$rest]
  }
  return $res
}
