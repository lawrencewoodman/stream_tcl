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

proc stream::create {first rest isEmpty {state 0}} {
  return [list $first $rest $isEmpty $state]
}

proc stream::first {stream} {
  lassign $stream first
  {*}$first $stream
}

proc stream::rest {stream} {
  set rest [lindex $stream 1]
  {*}$rest $stream
}

proc stream::isEmpty {stream} {
  set isEmpty [lindex $stream 2]
  {*}$isEmpty $stream
}

proc stream::map {cmdPrefix stream} {
  lassign $stream first rest isEmpty
  set mapper {{cmdPrefix first stream} {
    {*}$cmdPrefix [{*}$first $stream]
  }}
  create [list apply $mapper $cmdPrefix $first] $rest $isEmpty
}

proc stream::zip {args} {
  set zipperFirst {{thisStream} {
    set streams [lindex $thisStream 3]
    set res [::list]
    foreach stream $streams {
      lassign $stream first
      lappend res [{*}$first $stream]
    }
    return $res
  }}

  set zipperRest {{thisStream} {
    lassign $thisStream first rest isEmpty streams
    set res [::list]
    foreach stream $streams {
      set _rest [lindex $stream 1]
      lappend res [{*}$_rest $stream]
    }
    stream create $first $rest $isEmpty $res

  }}

  set zipperIsEmpty {{thisStream} {
    set streams [lindex $thisStream 3]
    foreach stream $streams {
      set isEmpty [lindex $stream 2]
      if {[{*}$isEmpty $stream]} {
        return 1
      }
    }
    return 0
  }}

  create [list apply $zipperFirst]   \
         [list apply $zipperRest]    \
         [list apply $zipperIsEmpty] \
         $args
}

proc stream::foldl {cmdPrefix initialValue stream} {
  lassign $stream first rest isEmpty
  set acc $initialValue
  while {![{*}$isEmpty $stream]} {
    set acc [{*}$cmdPrefix $acc [{*}$first $stream]]
    set stream [{*}$rest $stream]
  }
  return $acc
}

proc stream::toList {stream} {
  lassign $stream first rest isEmpty
  set res [::list]
  while {![{*}$isEmpty $stream]} {
    lappend res [{*}$first $stream]
    set stream [{*}$rest $stream]
  }
  return $res
}
