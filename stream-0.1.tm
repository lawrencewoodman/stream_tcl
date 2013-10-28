# A stream ensemble
#
# Copyright (c) 2013 Lawrence Woodman <lwoodman@vlifesystems.com>
#
# Licensed under an MIT licence.  Please see LICENCE.md for details.
#

package require Tcl 8.5

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

proc stream::foldl {cmdPrefix initialValue stream} {
  set acc $initialValue
  while {![isEmpty $stream]} {
    lassign $stream first rest
    set acc [{*}$cmdPrefix $acc $first]
    set stream [{*}$rest]
  }
  return $acc
}

proc stream::isEmpty {stream} {
  expr {[llength $stream] == 0}
}

proc stream::map {cmdPrefix args} {
  set numArgs [llength $args]
  if {$numArgs == 1} {
    MapSingleStream $cmdPrefix [lindex $args 0]
  } elseif {$numArgs > 1} {
    MapMultiStream $cmdPrefix {*}$args
  } else {
    Usage "stream map cmdPrefix stream ..."
  }
}


proc stream::rest {stream} {
  set rest [lindex $stream 1]
  {*}$rest
}

proc stream::take {num stream} {
  lassign $stream first rest
  if {[isEmpty $stream] || $num <= 0} {
    return [::list]
  } else {
    create $first [list take [expr {$num - 1}] [{*}$rest]]
  }
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
  return [create $firsts [list zip {*}$restStreams]]
}

#################################
#           Internal
#################################

proc stream::MapSingleStream {cmdPrefix stream} {
  lassign $stream first rest
  if {[isEmpty $stream]} {
    return $stream
  }
  create [{*}$cmdPrefix $first] [list MapSingleStream $cmdPrefix [{*}$rest]]
}

proc stream::MapMultiStream {cmdPrefix args} {
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
  return [create [{*}$cmdPrefix {*}$firsts] \
                 [list MapMultiStream $cmdPrefix {*}$restStreams]]
}

proc stream::Usage {msg} {
  return -code error -level 2 "wrong # args: should be \"$msg\""
}
