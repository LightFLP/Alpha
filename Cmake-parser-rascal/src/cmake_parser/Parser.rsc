module cmake_parser::Parser

import ParseTree;

import cmake_parser::Syntax;

public start[Build] parse(str src, loc path) = parse(#start[Build], src, path);
public start[Build] parse(loc origin) = parse(#start[Build], origin);