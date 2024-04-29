module cmake::Parser

import cmake::Syntax;
import ParseTree;

public start[Build] parse(str src, loc path) = parse(#start[Build], src, path);
public start[Build] parse(loc origin) = parse(#start[Build], origin);