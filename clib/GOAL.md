I would like the code at ../nano-colour to be converted into a library that we can use in other programs.
This directory contains a skeleton RISC OS program that we can expand.

I would like the nano-colouring algorithm (just the colouring algorithm) to be processed in this code.
Given some source code, I would like a library to read the file into memory in one block and then
break the file into separate regions of colours.

There should be a way to read a single nanorc file (ignoring the includes) and process its content
into structured data that we can parse when we need to colour the file.

We should just use this method initially to process nanorc files.

What I would like to get out of the colouring function is:

* A structure that represents the colouring which includes:
  * a pointer to the file contents in memory.
  * the length of the file contents.
  * a count of the number of lines.
  * pointer to a list of coloured line structures (with 'count of number of lines' entries).
* Each coloured line structure should be:
  * A count of the line number it represents in the source file.
  * A list of line elements structures (this could be an array of the elements, or a linked list).
* Each line element structure should consist of:
  * a horizontal character position for the element of the line.
  * a pointer to the start of the text in the file contents.
  * the length of the text.
  * a representation of the colour that should be used (maybe an enum of the colours, or a struct 
    representing the colour + the properties that the text has).

You should be able to build this structure for a given file.

There is an example CMHG file called modhead. We should be able to decode this into a structure that is 
described as above. Make the command line version of this tool call the decoder and print out the 
structured information, so that we can do something like 'riscos-build-run aif32 nanorcs --command 
"aif32.NanoColour modhead nanorcs.cmhg/nanorc"' and see what results we have for the colouring.

There is a regex library included in the main.h. This regex library can be found at 
/riscos-resources/Export/Lib/Regex/h/regex - use it as much as you can so that we're not re-inventing 
things, BUT if it would be easier to use string operations from the standard library or a simple search, 
do that in a function instead of invoking the regular expressions.
