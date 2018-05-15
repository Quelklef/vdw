
import strutils
import math

template high[T: uint64](t: typedesc[T]): uint64 = 18446744073709551615'u64
template low[T: uint64](t: typedesc[T]): uint64 = 0'u64

proc iceil(x: float32): int = return int(x.ceil)
proc iceil(x: float64): int = return int(x.ceil)

type TwoColoring*[S: static[int]] = distinct array[iceil(S / 64), uint64]

template uintc[S](col: TwoColoring[S]): int = iceil(S / 64) # The number of contained uint64s

template uints[S](col: TwoColoring[S]): auto =
    ## Allow for access of underlying uints
    cast[array[uintc(col), uint64]](col)
template muints[S](col: TwoColoring[S]): auto =
    ## Allow for mutation of underlying uints
    array[uintc(col), uint64](col)

proc `$`*[S](col: TwoColoring[S], on = "1", off = "0"): string =
    result = ""
    var isfirst = true
    for i, ui in uints(col):
        if isfirst:
            isfirst = false
        else:
            result &= ":"
        for dig in 0 ..< 64:
            if i * 64 + dig >= S:
                break
            result &= (if 1'u64 == ((ui shr dig) and 1): on else: off)

proc `[]`*[S](col: TwoColoring[S], i: range[0 .. S - 1]): range[0 .. 1] =
    return 1'u64 and col.uints[i div 64] shr (i mod 64)

proc `[]=`*[S](col: var TwoColoring[S], i: range[0 .. S - 1], val: range[0 .. 1]) =
    if val == 1:
        col.muints[i div 64] = col.uints[i div 64] or      1'u64 shl (i mod 64)
    else: # val == 0
        col.muints[i div 64] = col.uints[i div 64] and not 1'u64 shl (i mod 64)

proc `+=`*[S](col: var TwoColoring[S], amt: uint64) =
    col.muints[0] += amt
    col.muints[1] += (col.uints[0] < amt).uint64

