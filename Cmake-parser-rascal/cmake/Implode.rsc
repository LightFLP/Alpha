module cmake::Implode

import cmake::Parser;
import cmake::AST;

import ParseTree;
import Node;

public Build implode(Tree pt) = implode(#Build, pt);
public Build load(loc l) = implode(#Build, parse(l));