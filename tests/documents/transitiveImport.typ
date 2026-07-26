// fletcher depends on cetz, which in turn depends on oxifmt.
// Importing it exercises the whole dependency closure, not just the
// packages named in `typstEnv`.
#import "@preview/fletcher:0.5.8": diagram, edge, node

#diagram(
  node((0, 0), [Success!]),
  edge("-|>"),
  node((1, 0), [Success!]),
)
