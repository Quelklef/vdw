
import twoColoring
import nColoring

export TwoColoring
export NColoring

import hashes
import macros

macro coloringImpl*(C: static[int]): untyped =
    if C == 2:
        return ident("TwoColoring")
    else:
        return nnkBracketExpr.newTree(ident("NColoring"), newIntLitNode(C))

type Coloring*[C: static[int]] = object
    data*: coloringImpl(C)

proc initColoring*(C: static[int], N: int): Coloring[C] =
    when C == 2:
        result.data = initTwoColoring(N)
    else:
        result.data = initNColoring(C, N)

template export_varColoring_void(function: untyped): untyped =
    proc `function`*(col: var Coloring) {.inline.} =
        function(col.data)

export_varColoring_void(randomize)

template export_varColoring_uint64_void(function: untyped): untyped =
    proc `function`*(col: var Coloring, amt: uint64) {.inline.} =
        function(col.data, amt)

export_varColoring_uint64_void(`+=`)

template export_Coloring_range_0S_range_0C(function: untyped): untyped =
    proc `function`*[C](col: Coloring[C], i: int): range[0 .. C - 1] {.inline.} =
        return function(col.data, i)

export_Coloring_range_0S_range_0C(`[]`)

template export_varColoring_range_0S_range_0C_void(function: untyped): untyped =
    proc `function`*[C](col: var Coloring[C], i: int, val: range[0 .. C - 1]) {.inline.} =
        function(col.data, i, val)

export_varColoring_range_0S_range_0C_void(`[]=`)

template export_Coloring_string(function: untyped): untyped =
    proc `function`*[C](col: Coloring[C]): string {.inline.} =
        return function(col.data)

export_Coloring_string(`$`)

template export_Coloring_Hash(function: untyped): untyped =
    proc `function`*[C](col: Coloring[C]): Hash {.inline.} =
        return function(col.data)

export_Coloring_Hash(hash)

template export_Coloring_Coloring_bool(function: untyped): untyped =
    proc `function`*[C](colA, colB: Coloring[C]): bool {.inline.} =
        return function(colA.data, colB.data)

export_Coloring_Coloring_bool(`==`)

when isMainModule:
    import typetraits

    # Test merging types

    var tc = initColoring(2, 128)
    var nc = initColoring(5, 128)

    echo(tc.data.type.name)
    echo(nc.data.type.name)

    tc += 2
    nc += 5

    echo tc
    echo nc

    # Test creating new proc

    proc test[C](col: Coloring[C]) =
        echo($C)

    test(tc)
    test(nc)

