import node
import graph
import random
import io
import math
import locks
import strutils
import os
import sequtils
import misc
import times

random.randomize()

let tabular = initTabular(
    ["Vertices", "Edges", "Shuffles"],
    [ 3        ,  2     , 10        ],
)
proc report(values: varargs[string, `$`]) =
  echo tabular.row(values)

proc turanDisplay*(n: int, e: int = -1): void =
  var edges = e
  if float(e) > n*(n-1)/2:
    edges = int(n*(n-1)/2)
    echo "Too many edges, defaulting to ", edges, " edges"

  var g: Graph
  if e < 0:
    g = initRandGraph(n)
  else:
    g = initRandGraph(n, edges)

  var turanNum = float(size(g))/(2*numE(g)/size(g) + 1)

  echo "n = ", size(g), ", e = ", numE(g)
  echo "Turan's Theorm: n/(2e/n + 1) = ", turanNum

  var count = 1
  while float(iSet(g)) < turanNum:
    count += 1
    shuffle(g)
  echo "Shuffled ", count, " times"
  display(g)

proc zeroSeq(n: int): seq[int] =
  for i in 0 ..< n:
    result.add(0)

iterator increment(start: float, stop: float, inc: float): float =
  var i = start
  while i < stop:
    yield i
    i += inc

###TESTING THINGS
var n = 20
var inc = 0.1
var numTrials = 1000
const numThreads = 12

case paramCount()
of 1:
  n = paramStr(1).parseInt
of 2:
  n = paramStr(1).parseInt
  inc = paramStr(2).parseFloat
of 3:
  n = paramStr(1).parseInt
  inc = paramStr(2).parseFloat
  numTrials = paramStr(3).parseInt
else:
  echo "You seem to have messed up cmd line args, using default values: ", n, ", ", inc, ", ", numTrials

var threads: array[numThreads, Thread[int]]
proc trials*(w: int) {.thread.}
proc main*() =
  for i in 0 ..< numThreads:
    threads[i].createThread(trials, i)
  joinThreads(threads)

  var names: seq[string] = @[]
  var p = 0.0
  while p <= 1:
    names.add("Turan_" & intToStr(n) & "_" & p.formatFloat(ffDecimal, 2) & ".txt")
    p = round(p + inc, 2)
  echo "File saved as: ", "Turan_" & intToStr(n) & ".txt"

var prob: float = 0.0

proc probTuran*(p: float): tuple[diff: float, shuffles: int] =
  var g: Graph
  var e: int

  g = initProbGraph(n, p)
  shuffle(g)
  e = numE(g)
  var turanNum = float(n)/(2*e/n + 1)
  var numS = 1
  while float(iSet(g)) < turanNum:
    numS += 1
    shuffle(g)
  return (diff: float(iSet(g)) - turanNum, shuffles: numS)

proc trials*(w: int) {.thread.} =
  if prob <= 1:
    var p = prob
    prob = round(prob + inc, 2)

    let fileName = "Turan_" & intToStr(n) & "_" & p.formatFloat(ffDecimal, 2) & ".txt"
    let file = open(fileName, mode = fmAppend)
    var startTime: float

    try:
      startTime = cpuTime()
      for _ in 0 ..< numTrials:
        let (d, s) = probTuran(p)
        file.writeRow(p, s, d)
        #[ #per trial output
        echo zip([$p, $s, $(round(d, 1))], [4, 3, 4]) #implements tabular's display method without memory accessing problems
                   .mapIt(align(it[0], it[1]))
                   .joinSurround(" | ")
                   ]#
    finally:
      close(file)
    concatFile("Turan_" & intToStr(n) & ".txt", fileName)
    removeFile(fileName)
    echo "p = ", p.formatFloat(ffDecimal, 2), " done by thread ", w, " in ", round(cpuTime() - startTime, 2), "s"
    trials(w)

when isMainModule:
  main()

#Finds numShuffles for all simple graphs that have n nodes and e edges
proc turanAll*(n:int, e:int): seq[int] =
  var turanNum = float(n)/(2*e/n + 1)
  for i in comb(n, e):
    var g:Graph = initGraph(n)
    var numS = 1
    for j in i:
      addE(n, j, g)
    shuffle(g)
    while float(iSet(g)) < turanNum:
      numS += 1
      shuffle(g)
    result.add(numS)

proc turan*(n: int, e: int = -1): int =
  result = 1
  var edges = e
  if float(e) > n*(n-1)/2:
    edges = int(n*(n-1)/2)
  var g: Graph
  if e < 0:
    g = initRandGraph(n)
  else:
    g = initRandGraph(n, edges)
  var turanNum = float(size(g))/(2*numE(g)/size(g) + 1)
  while float(iSet(g)) < turanNum:
    result += 1
    shuffle(g)

#[
echo tabular.title()
# TODO: for some reason n =1 doesn't work, shouldn't matter tho
for n in 1 .. 10:
  for e in n-1 .. int(n*(n-1)/2):
    #report(n, e, turan(n, e))
    for o in turanAll(n, e):
      report(n, e, o)
close(outFile)
]#
