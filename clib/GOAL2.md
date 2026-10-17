We want to allow the library to be able to render to the screen.
The GContext library is linked with the test binary. This is included in the example file c/testgcontext.
The test program is purely a demonstration of how the library works.

Create a new file c/nanocolour_render which contains functions for rendering the
decoded elements.

There should be a creation function which takes a decoded structure and a gcontext,
and a font handle, and holds information about it. It may include acceleration details
like the offset of lines (so that a faster redraw can be performed).
The functions should allow:

* the sizing of the entire text - given the decoded structures, return the rendering size (gcontext has 
  structures for bounds and for bounding boxes).

* rendering the entire text with the top left position specified, and a background colour which should be 
  used behind the whole content (or might be `COLOUR_NONE` to not draw anything). Optionally might be 
  given a `bbox_t` which reports how much of the screen should be redrawn (to allow a fast reject and
  jump to lines).

* releasing of the rendering structure.

* Changing the font handle (which would invalidate any cached size and line offset table).
