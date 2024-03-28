module cmake::Implode

import ParseTree;
import Node;

import cmake::Parser;
import cmake::AST;

public Build implode(Tree pt) = implode(#Build, pt);
public Build load(loc l) = implode(#Build, parse(l));