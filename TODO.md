# Goals
## General Roadmap

#### A TOOL FOR WRITING
*  Two differing goals for efficiently expressing content:
   -  Simple as hell markdown formatting, for managing content without needing to know markup.
   -  As-abstractly-complex-as-required template language, for managing the broad complexity of the possible markup.
*  A modular architecture which will allow the pieces to be reusable and re-packagable without much configuration.
*  A no-nonsense, flat file post architecture (for starters). Likely there will be more modules to allow additional database storage.

#### A SIMPLE-ASS SERVER
*  Serve files and static assets
*  Integrate with common existing servers (express & hapi)

#### A COMMAND LINE TOOL FOR NON-COMMANDERS
*  Simple interface allows you to generate both markup and markdown documents.
*  Verify a post will convert to a page without any of the headache; easily export parts of the server, for re-use elsewhere.
*  Compress and Uncompress existing posts, so you can manage your own backups easily.
*  Additional interfaces for integration with things like S3 and other server storage solutions will likely be needed.
