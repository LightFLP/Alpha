module cmake::Parser

import ParseTree;

import cmake::Syntax;

public start[Build] parse(str src, loc path) = parse(#start[Build], src, path);
public start[Build] parse(loc origin) = parse(#start[Build], origin);