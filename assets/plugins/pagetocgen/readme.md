KNOWN BUGS: 
- default value for $end_level doesn't work, you must specify it explicitly
- the start configuration marker seems to be required, even though it's not supposed to be.

TO DO:
- use a simplified syntax to call the plugin, perhaps something like: 
		*[pageTOC? &start_level=`2` &heading_tag=`h2`]* // this is where the output would go (eliminating the need for that tag)
		*[startTOC]*
		*[endTOC]*
		(Note: making the opening tag visible in the rich text editor (e.g. *[ ]*, instead of <!-- -->) has the benefit of ensuring non-technical people don't accidentally delete the comments when editing the page) 
- If I do this, create an optional backwards compatibility mode, as an external include
- extract the functions and documentation to external files in the assets folder, leaving only the parameters in plugin
- make sure multiple instances of TOCs can exist on the same page
- give the option to use existing anchors, instead of the automatically generated ones
- give the option to have no heading for the TOC
- and option to have no surrounding tag around TOC
- make code more efficient by looking for the output tag, and if it isn't there, stop running the code, so it doesn't slow down the pages that don't use the TOC plugin
