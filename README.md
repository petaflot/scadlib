# scadlib

A pretty straightforward library that makes OpenSCAD a little less of a pain to use and includes a few goodies. It includes:

- a freely-placeable XYZ referential that helps when you're lost with tons of level of transformations
- a new `prism` primitive that kinda `cube` and `cylinder`[^cones] primitives, including the ability to make empty prismatic shells
- a wrapper around gears that is much more manufacturing-oriented ; it makes it very easy to make geared systems with known position of the axes
- a python script to generate horns or pipes as a sequence of items

Dependencies on other libs:

* [Parametric Involute Bevel and Spur Gears by GregFrost](http://www.thingiverse.com/thing:3575) (included, may not be the latest version)

[^cones]: not for cones
