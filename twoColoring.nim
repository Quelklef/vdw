import strutils

import ../util

template high[T: uint64](t: typedesc[T]): uint64 = 18446744073709551615'u64
template low[T: uint64](t: typedesc[T]): uint64 = 0'u64

proc ceildiv(x, y: int): int =
  ## Like `x div y` but instead of being eq to floor(x/y), is eq to ceil(x/y)
  result = x div y
  if x mod y != 0: result.inc

#[
We encode two-colorings as sequences of uint64s.
Each uint64 (henceforth 'uis') represent 64 colorings.
The LEAST SIGNIFICANT digit of each ui represent the
first coloring, and the MOST SIGNIFICANT represents the
last coloring.

We maintain the following state:
- There are never more uis than there need to be
]#
type TwoColoring* = ref object
  N*: Positive
  data*: seq[uint64]

# The project scope is limited to 2-colorings right now and this acts
# as a dummy type for extensibility reasons
type Coloring* = TwoColoring
# A bona fide Coloring type would have a `c` attribute so we emulate
# that with a template
template C*(tc: TwoColoring): Positive = 2

proc initTwoColoring*(N: int): TwoColoring =
  new(result)
  result.N = N
  result.data = @[]
  for _ in 1 .. ceildiv(N, 64):
    result.data.add(0'u64)

proc `==`*(col0: TwoColoring; col1: Coloring): bool =
  return col1 of TwoColoring and col0.N == col1.N and col0.data == col1.TwoColoring.data

proc asBinReversed(x: uint64): string =
  ## Return the binary string representation of a uint64, reversed
  result = ""
  for i in 0 ..< 64:
    result &= $(1'u64 and (x shr i))

proc `[]`*(col: TwoColoring, i: int): int
proc `$`*(col: TwoColoring): string =
  result = ""
  for ui in col.data:
    result &= asBinReversed(ui)
  result = result[0 ..< col.N]

proc `{}`(col: TwoColoring, i: int): int =
  return int(1'u64 and (col.data[i div 64] shr (i mod 64)))

proc `{}=`(col: var TwoColoring, i: int, val: int) =
  if val == 1:
    col.data[i div 64] = col.data[i div 64] or      (1'u64 shl (i mod 64))
  else: # val == 0
    col.data[i div 64] = col.data[i div 64] and not (1'u64 shl (i mod 64))

proc `[]`*(col: TwoColoring, i: int): int =
  when compileOption("boundChecks"):
    if i >= col.N:
      raise newException(IndexError, "Index $# out of bounds" % $i)
  return col{i}

proc `[]=`*(col: var TwoColoring, i: int, val: int) =
  when compileOption("boundChecks"):
    if i >= col.N:
      raise newException(IndexError, "Index $# out of bounds" % $i)
  col{i} = val

proc randomize*(col: var TwoColoring): void =
  ## Randomize a two-coloring
  for i in 0 ..< col.data.len:
    col.data[i] = rand_u64()

proc homogenous*(col, mask: TwoColoring): bool =
  ## Are all the colors specified by the mask the
  ## same coloring?
  when compileOption("checks"):
    if col.N != mask.N:
      raise ValueError.newException("Coloring and mask must be the same size.")
  for i in 0 ..< col.data.len:
    if not ((col.data[i] and mask.data[i]) == 0 or ((col.data[i] or not mask.data[i]) == uint64.high)):
      return false
  return true

proc shiftRightImpl(col: var TwoColoring; overflow: uint64; i: int) =
  # Note that we implement this as a "shift left" since the colorings are stored
  # in order of significance, not canonical order
  if i >= col.data.len:
    return
  let recurOverflow = col.data[i] shr 63
  col.data[i] = (col.data[i] shl 1) or overflow
  col.shiftRightImpl(recurOverflow, i + 1)

proc shiftRight*(col: var TwoColoring) =
  ## In-place shift right
  col.shiftRightImpl(0, 0)

proc `or`*(col0: TwoColoring; col1: Coloring): Coloring =
  # TODO: this multiproc is kinda ugly
  ## Result takes the length of the longest coloring
  let col1 = cast[TwoColoring](col1)
  var resultData = newSeq[uint64](max(col0.data.len, col1.data.len))
  for i in 0 ..< min(col0.data.len, col1.data.len):
    resultData[i] = col0.data[i] or col1.data[i]
  return TwoColoring(N: max(col0.N, col1.N), data: resultData)

func `+=`*(col: var TwoColoring, amt: uint64) =
  ## May overflow
  col.data[0] += amt
  if col.data.len > 1:
    col.data[1] += (col.data[0] < amt).uint64
