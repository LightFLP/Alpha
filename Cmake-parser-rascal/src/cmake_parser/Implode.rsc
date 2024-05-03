module cmake_parser::Implode

import cmake_parser::Parser;
import cmake_parser::AST;

import ParseTree;
import Node;

public Build implode(Tree pt) = implode(#Build, pt);
public Build load(loc l) = implode(#Build, parse(l));