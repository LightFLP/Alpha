module utils::Types

import lang::cpp::AST;
import lang::cpp::M3;

//aliases
public alias ModelContainer = tuple [M3, Declaration];

//ADTs
public data ClassEntity = classEntity(str className, ModelContainer modelContainer);