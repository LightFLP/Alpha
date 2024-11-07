module utils::Types

import lang::cpp::AST;
import lang::cpp::M3;

//aliases
public alias ModelContainer = tuple [M3, Declaration];

//ADTs
public data ClassEntity = classEntity(str className, ModelContainer modelContainer);
public data Configuration = configuration(str inputFolderAbsolutePath, bool saveFilesAsJson, bool composeModels, bool verbose, bool saveUnresolvedIncludes);