module lang::cmake::Implode

import lang::cmake::Parser;
import lang::cmake::AST;

import ParseTree;
import Node;

public Build implode(Tree pt) = implode(#Build, pt);
public Build load(loc l) = implode(#Build, parse(l));