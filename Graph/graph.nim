import node
import random
import sequtils
import math
import tables
import io
import misc

type Graph = object
  nodes: seq[Node]

func size*(g: Graph): int =
  return g.nodes.len

#Counts edges in undirected multigraphs
func numE(g: Graph): int =
 result = 0
 for i, n in g.nodes:
   result += n.vertices.len
 result = int(result/2)

#makes a sequence of nodes with names a, b, c, etc
func seqNodes(num: int): seq[Node] =
  for i in 0 ..< num:
    result.add(initNode((chr(ord('a') + i))))

proc initGraph(n: int): Graph =
  result.nodes = seqNodes(n)

proc shuffle*(g: var Graph): void =
  var newSeq: seq[Node] #new sequence to replace g.nodes
  newSeq = @[]
  var pos: int
  for i in 0 ..< size(g): #pick a random node in g.node and add to newSeq, then remove it from g.nodes
    pos = rand(size(g)-1)
    newSeq.add(g.nodes[pos])
    g.nodes.del(pos)
  g.nodes = newSeq #replace g.nodes with newSeq
  for i, n in g.nodes: #assign nodes position in accending order
    n.position = i

#makes simple graph
#multigraphs can be treated as simple graphs for independent sets
proc initRandGraph*(n: int): Graph =
  result = initGraph(n)
  #n-1 is min num of edges in a graph, n*(n-1)/2 is max
  #returns random number inbetween min and max
  var numEdges = rand(int(n*(n-1)/2) - (n-1)) + (n-1)
  var seqE: seq[int] = @[]
  #[
  Explanation: of code below:
  seqE contains numbers 1 to n(n-1)/2 with each number corresponding to an edge relationship between two vertices
  Imagine an edge map
  _| A B C D
  A  X 1 2 3    (contains n-1 numbers)
  B  X X 4 5    (contains n-2 numbers)
  C  X X X 6    (contains n-3 numbers)
  D  X X X X    ..n=0
  Above is the what a value in seqE represents relationship-wise
  (Note: we only care about SIMPLE GRAPHS as multigraphs are basically the same in regards to Turan's theorem)
  Following this pattern, there are two numbers to keep track of: the column and row
  In the code we keep track of a(the row) and a+b (the column)
  ]#
  for i in 1 .. int(n*(n-1)/2):
    seqE.add(i)
  for i in 0 ..< numEdges:
    var i = rand(seqE.len-1)
    var b = seqE[i]
    seqE.delete(i)
    var a = 0
    while b - (n - 1 - a) > 0:
      b -= (n - 1 - a)
      a += 1
    addVertex(result.nodes[a], result.nodes[a+b])
    addVertex(result.nodes[a+b], result.nodes[a])
  shuffle(result)

func findIndSetRight(g: Graph): seq[Node] =
  for n in g.nodes:
    if not testRight(n):
        result.add(n)

func findIndSetLeft(g: Graph): seq[Node] =
  for n in g.nodes:
    if not testLeft(n):
        result.add(n)

func iSet*(g: Graph): seq[int] =
 return @[findIndSetLeft(g).len, findIndSetRight(g).len]

#shuffles the positions of all the nodes within g
#[
func shuffle*(g: Graph) =
  let nums = toSeq(0 ..< g.size)
  for pair in zip(g.nodes, nums):
    setPosition(pair.a, pair.b)
proc shuffle*(g: Graph): void =
  var nums: seq[int]
  for i in 0 ..< size(g):
    nums.add(i) #sequence from 0 to number of nodes - 1
  var pos: int
  for n in g.nodes: #pick a random index in nums, assign value at index to node, remove that index from nums
    pos = rand(nums.len-1)
    n.position = nums[pos]
    nums.del(pos)
]#
let tabular = initTabular(
    ["Position", "Name", "Connected to", "Left Ind.", "Right Ind."],
    [2         , 1     , 14           , 0          , 0],
)



proc report(values: varargs[string, `$`]) =
    echo tabular.row(values)

proc toString*(g: Graph): string =
  echo tabular.title()
  for n in g.nodes:
    var edges = ""
    for e in n.vertices:
      edges.add(" " & e.name)
    #result.add("\n" & $n.position & " (" & n.name & "):" & edges)
    report(n.position, n.name, edges, not testLeft(n), not testRight(n))
  var l = findIndSetLeft(g)
  var r = findIndSetRight(g)
  var temp: string = ""
  for node in l:
    temp.add(" " & node.name)
  echo "Ind. Set Left (" & $l.len & "):", temp
  temp = ""
  for node in r:
    temp.add(" " & node.name)
  echo "Ind. Set Right (" & $r.len & "):", temp
  echo "Nodes: ", size(g)
  echo "Edges: ", numE(g)
#[
func iSet*(g: Graph): int =
  shuffle(g)
  result = findIndSetLeft(g).len
  #result = findIndSetRight(g).len
]#
