module cmake::PathExtractor

import cmake::AST;
import cmake::Parser;  
import cmake::Implode;
import cmake::Utils;

import Prelude;
import ParseTree;
import Location;
import util::FileSystem;

map[str, map[str, list[str]]] macroPathByProject = ();              // key: project name, value: mappings from the macro to the location
map[str, map[str, list[str]]] macroVariableByProject = ();          // key: project name, value: mappings from the macro to the variable values;
map[loc, set[loc]] cmakeToIncludePath = ();                         // key: cmake, value: included headers in the project; project is the minimal unit for path inclusion
map[loc, set[loc]] cmakeToStdlib = ();                              // key: cmake, value: std lib (external dependencies)
map[loc, set[loc]] cmakeToSource = ();                              // key: cmake, value: sources
map[str, str] childToParent = ();                                   // key: name of the child cmake project, value: name of the parent cmake project --> if a macro is not found, then search the parent node until to the root
map[loc, str] fileToProject = ();                                   // key: cmake, value: project;
public set[loc] sourceTest = {};                                    // set of sources used for test lib
public set[loc] sourceProduction = {};                              // set of sources used for production lib
public set[loc] sourcePureTest = {};                                // sourceTest - sourceProduction
public set[loc] sourceVxworks = {};                                 // set of source files in VxWorks
public set[loc] headerVxworks = {};                                 // set of headers in VxWorks
public map[loc, set[loc]] sourceTestByCmake = ();                   // for each cmake, collect a list of source and header files of test code
public map[loc, set[loc]] sourceProductionByCmake = ();             // for each cmake, collect a list of source and header files of production code
public map[loc, set[loc]] headerTestByCmake = ();    
public map[loc, set[loc]] headerProductionByCmake = ();    
public map[loc, set[loc]] cmakeToKeySource = ();                    // key: cmake, value: sources, deiierence to cmakeToSource: only collect the files in SOURCES keyword, the source files in DIRS are excluded
public rel[loc, set[loc]] cmakeToIncRel = {};
public rel[loc, list[loc]] sourceToIncRel = {};
public rel[loc, list[loc]] sourceToStdlibRel = {};
list[loc] cmakeFiles = [];
public loc ROOT = |unknown:///|;

public void extract(list[loc] skipCmakes, map[str, list[str]] rootMacroMap, loc toolchainCmake, loc rootCmake, list[loc] targets, loc codebaseRoot, loc externalDir, list[loc] targetsOriginal) {
    ROOT = codebaseRoot;
    macroPathByProject += ("ROOT" : rootMacroMap + ("PROJECT_SOURCE_DIR" : [toolchainCmake.parent.uri])); // add a dummy project ROOT to initialize the map
    macroVariableByProject += ("ROOT" : ()); // add a dummy project ROOT to initialize the map
    childToParent = ();
    parseCmake(toolchainCmake, "ROOT", true, skipCmakes, targets, externalDir, ""); // prepare some global macros
    macroPathByProject["ROOT"] = delete(macroPathByProject["ROOT"], "PROJECT_SOURCE_DIR");
    parseCmake(rootCmake, "ROOT", true, skipCmakes, targets, externalDir, "");

    iprintln("Parsing is completed.");
    iprintln("Number of parsed cmake files: <size(toSet(cmakeFiles))>");

    generateCmakeRelations(targetsOriginal);
}

// convert map to relation as relation operation is fast
void generateCmakeRelations(list[loc] targetsOriginal){
    set[loc] sourceFiles = {*cmakeToSource[cmake] | cmake <- cmakeToSource<0>};
    cmakeToIncRel = {<x, cmakeToIncludePath[x]> | x <- cmakeToIncludePath<0>};
    rel[loc, set[loc]] cmakeToStdlibRel = {<x, cmakeToStdlib[x]> | x <- cmakeToStdlib<0>};
    // get a mapping from source to cmake file --> make the preparation for clair parameters
    rel[loc, loc] sourceToCmakeRel = {<val, key> | key <- cmakeToSource, val <- cmakeToSource[key]};
    // generate mappings: (source, include path), (source, stdlib)
    rel[loc, set[loc]] sourceToIncSets = sourceToCmakeRel o cmakeToIncRel;
    rel[loc, set[loc]] sourceToStdlibSets = sourceToCmakeRel o cmakeToStdlibRel;
    sourceToIncRel = {<x, toList(toSingleSet(sourceToIncSets[x]))> | x <- sourceFiles};
    sourceToStdlibRel = {<x, toList(toSingleSet(sourceToStdlibSets[x]))> | x <- sourceFiles};
    sourcePureTest = sourceTest - sourceProduction;

    missed = missedFiles(targetsOriginal, sourceToCmakeRel);
}

void parseCmake(loc root, str projectName, bool isLeaf, list[loc] skipCmakes, list[loc] targets, loc externalDir, str binPath){
    isLeaf = true;
    if(root notin fileToProject<0>){    // avoid duplicated records
        fileToProject += (root : projectName);
        cmakeFiles += root;
    }
    iprintln(root);
    if(root in skipCmakes){
        return;
    }
    p = parse(root);
	y = implode(p);

    cmakeToIncludePath += (root : {root.parent}); // default: parent dir of each cmake file is a include path
    // parse from the root cmake
    isLeaf = parseStatement(root, y, projectName, isLeaf, skipCmakes, targets, externalDir, binPath);
}

bool parseStatement(loc root, Build y, str projectName, bool isLeaf, list[loc] skipCmakes, list[loc] targets, loc externalDir, str binPath){
    set[str] children = {};
    visit(y){
        case projStat(_, name): {
            // each time creating a new cmake project, save the macro-path pairs in a specific map
            childToParent += (name : projectName);
            projectName = name;
            macroPathByProject += (projectName : ("PROJECT_SOURCE_DIR": [root.parent.uri]));
            macroVariableByProject += (projectName : ("PROJECT_SOURCE_DIR": [root.parent.uri]));
            indices = findAll(root.uri, "/");
            if((/poscore/i := root.uri || /poscorered/i := root.uri || /poscpt/i := root.uri) && size(indices) >= 6){
                str bin = binPath == ""? findMacro("PROJECT_BINARY_DIR", projectName)<0>[0] : binPath;
                bin = bin + root.uri[indices[4] .. indices[5]];
                assert exists(toLocation(bin)) : "";
                macroPathByProject += (projectName : ("PROJECT_BINARY_DIR": [bin]));
            }else{
                macroPathByProject += (projectName : ("PROJECT_BINARY_DIR": [binPath]));
            }
        }
        case configureProject(name): {
            str suffix = "";
            list[str] prefixList = findMacroParameter(name, projectName)<0>;
            str prefix = !isEmpty(prefixList)? prefixList[0] : name;
            list[str] suffixList = findMacroParameter("BUILD_COLOR", projectName)<0>;
            if(isEmpty(suffixList)){
                iprintln("BUILD_COLOR unknown");
                suffix = "UNKNOWN";
            }else{
                suffix = suffixList[0];
            }
            str childName = prefix + "_" + suffix;
            childToParent += (childName : projectName);
            projectName = childName;
            macroPathByProject += (projectName : ("PROJECT_SOURCE_DIR": [root.parent.uri]));
            macroVariableByProject += (projectName : ("PROJECT_SOURCE_DIR": [root.parent.uri]));
            indices = findAll(root.uri, "/");
            if((/poscore/i := root.uri || /poscorered/i := root.uri || /poscpt/i := root.uri) && size(indices) >= 6){
                str bin = binPath == ""? findMacro("PROJECT_BINARY_DIR", projectName)<0>[0] : binPath;
                bin = bin + root.uri[indices[4] .. indices[5]];
                assert exists(toLocation(bin)) : "";
                macroPathByProject += (projectName : ("PROJECT_BINARY_DIR": [bin]));
            }else{
                macroPathByProject += (projectName : ("PROJECT_BINARY_DIR": [binPath]));
            }
        }
        case addSubdir(_, _, macroName, _,  subPath, binDir): {
            set[str] paths = concatPaths(root, [macroName, subPath], projectName, externalDir);
            str binPath = isEmpty(binDir)? "" : getFirstFrom(concatPaths(root, [binDir[0].macroName, binDir[0].subPath], projectName, externalDir));
            if(!isEmpty(paths)){
                loc child = toLocation(getFirstFrom(paths)); // add_subdirectory() always add one path, thus concatPaths always create a set with one element 
                if(!isDirectory(child)){
                    iprintln(root);
                    iprintln(findMacro("PROJECT_SOURCE_DIR", projectName)<0>);
                    iprintln("Directory <child> not found");
                }
                bool cmakeExist = false;
                loc dir = |unknown:///|;
                for(path <- child.ls){
                    if(/^CMakeLists./ :=  path.file || /^CMakelists./ :=  path.file || path.extension == "cmake"){
                        dir = path;
                        cmakeExist = true;
                    }
                }
                if(cmakeExist){
                    parseCmake(dir, projectName, isLeaf, skipCmakes, targets, externalDir, binPath);
                }else{
                    iprintln("No CMake file under <child>");
                }   
            }else{
                iprintln("${<macroName>}/<subPath> not found");
            }
            isLeaf = false;
        }
        // if it is not a leaf node, then it doesn't have include paths for specific modules
        case include(_, sourceFile, _, sourcePath): { // include(), same to c/c++, the code is copied to the place it is included
            set[str] paths = concatPaths(root, [sourceFile, sourcePath], projectName, externalDir); 
            for(path <- paths){
                loc includedCmake = toLocation(path);
                if(isFile(includedCmake)){
                    isLeaf = parseIncludeStatement(includedCmake, projectName, isLeaf, skipCmakes, targets, externalDir, binPath);                    
                }else{
                    iprintln("<path> is not a file");
                }
            }
        }
        case includeDir(system, macroNameList): {    // In this codebase, include_directories() is only used for Qt5
            if(system == "SYSTEM"){
                list[str] found = findMacro("CMAKE_PREFIX_PATH", projectName)<0>;
                if(!isEmpty(found)){
                    str macroName = macroNameList[0].sourceFile;
                    int index = findFirst(macroName, "_");
                    str identifier = macroName[0 .. 2] + macroName[3 .. index];
                    found = [x | x <- found, (isDirectory(toLocation(x)) || isFile(toLocation(x)))];
                    str prefix = found[0];
                    str QtPath = prefix + "/include/" + identifier;
                    if(!exists(toLocation(QtPath))){
                        iprintln("Qt5 path <QtPath> does not exist");
                    }else{
                        if(/Gui/ := identifier){
                            addPathOrParamToMap(identifier, "", [QtPath, (ROOT + "BuildPos/Win/common/PosTest/xposer/src/xposer").uri], projectName);
                        }else{
                            addPathOrParamToMap(identifier, "", [QtPath], projectName);
                        }
                        
                    }
                }
            }else{
                iprintln("Non-system include dirsctories");   // by far, all include_directories are for SYSTEM include directories
            }
        }
        case setList(targetMacro, targetType, source): {
            list[str] foundEntity = findMacro(targetMacro, projectName)<0>;
            list[str] paths = [];
            for(s <- source){
                if(s is sourceListDollar){
                    paths += findMacro(s.sourceFile, projectName)<0>[-1] + s.path;
                }else{
                    paths += s.sourceFile;
                }
            }
            // list[str] paths = [s.sourceFile | s <- source];
            if(!isEmpty(foundEntity)){
                if(size(foundEntity) > 1){
                    iprintln("Multiple mappings for macro <targetMacro>");
                }
                for(entity <- foundEntity){ // entity: value of ${targetMacro}
                    // parse QT5
                    if(!isEmpty(paths) && targetType == "_LIBS"){    // if Qt5 libraries are required, add Qt5 paths to stdlib 
                        bool hasQt5 = false;
                        for(path <- paths){
                            if(/^Qt5/ := path){
                                hasQt5 = true;
                                str identifier = replaceFirst(path, "5::", "");
                                list[str] found = findMacro("CMAKE_PREFIX_PATH", projectName)<0>;
                                found = [x | x <- found, (isDirectory(toLocation(x)) || isFile(toLocation(x)))];
                                if(!isEmpty(found)){
                                    list[str] qt5PathList = findMacro(identifier, projectName)<0>;
                                    qt5PathList = isEmpty(qt5PathList)? [found[0] + "/include/Qt" + replaceFirst(path, "Qt5::", "")] : qt5PathList;
                                    str qt5Path = isEmpty(qt5PathList)? found[0] + "/include/Qt" + replaceFirst(path, "Qt5::", "") : qt5PathList[0];
                                    cmakeToStdlib = addSetValueToMap(root, {toLocation(x) | x <- qt5PathList}, cmakeToStdlib);
                                }
                            }
                        }
                        if(hasQt5){
                            list[str] found = findMacro("CMAKE_PREFIX_PATH", projectName)<0>;
                            found = [x | x <- found, (isDirectory(toLocation(x)) || isFile(toLocation(x)))];
                            if(!isEmpty(found)){
                                str qt5IncludePath = found[0] + "/include";
                                cmakeToStdlib = addSetValueToMap(root, {toLocation(qt5IncludePath)}, cmakeToStdlib);
                            }
                        }
                    }else{
                        list[str] concatedDirs = toList(concatPaths(root, paths, projectName, externalDir));
                        set[loc] concatedLocs = {toLocation(x) | x <- concatedDirs};
                        addPathOrParamToMap(entity, targetType, concatedDirs, projectName);
                        splitPathSet(root, targetType, concatedLocs, targets, externalDir);
                    }
                }
            }
            // else: target macro not found, already processed in findMacro function
        }
        case setMapping(targetMacro, source): {
            list[str] paths = [x.sourceFile | x <- source, /\</ !:= x.sourceFile];
            set[loc] concatedLocs = parseSetStatement(root, paths, targetMacro, projectName);
            splitPathSet(root, targetMacro, concatedLocs, targets, externalDir);
        }
        case setMultiMacMapping(targetMacro, sourcePre, sourcePost): {
            list[Source] sourcePathList = sourcePre + sourcePost;
            list[str] paths = [x.sourceFile | x <- sourcePathList];
            // iprintln("setMultiMacMapping");
            set[loc] concatedLocs = parseSetStatement(root, paths, targetMacro, projectName);
            splitPathSet(root, targetMacro, concatedLocs, targets, externalDir);
        }
        case option(targetMacro, words): {
            // for option(), in all cases, targetMacro is a parameter --> update directly in the map, no need to find first
            addPathOrParamToMap(targetMacro, "", [words[-1]], projectName);
        }
        case configureTestLibrary(targetMacro, params): {
            str embOption = params[0]; // assume 'argn' guarantees BUILD_${TARGET_NAME}_${EMB_OPTION} to be true
            str isTest = findMacro("BUILD_TEST_CODE", projectName)<0>[0];
            isTest = "ON"; // cmake parser cannot parse the if-conditions, but the value of BUILD_TEST_CODE depends on the if-statement. Thus, its value is directly specified here. 
            if(isTest == "ON" && (embOption == "OBJ_TN" || embOption == "OBJ_TN_VXWIN" || embOption == "VOB_TN" || embOption == "OBJ_VXWORKS")){
                separateSources(root, targetMacro, embOption, projectName, false, true);
            }
        }
        case configureTestExecutable(targetMacro, embOption, _): {
            str isTest = findMacro("BUILD_TEST_CODE", projectName)<0>[0];  // "BUILD_TEST_CODE" value is changed in root cmake with option()
            isTest = "ON";
            if (isTest == "ON" && (embOption == "OBJ_TN" || embOption == "VOB_TN" || embOption == "OBJ_TT")){
                separateSources(root, targetMacro, embOption, projectName, false, true);
            }
        }
        case configureClassTestExecutable(targetMacro, embOption, _): {
            str isTest = findMacro("BUILD_TEST_CODE", projectName)<0>[0];
            isTest = "ON";
            if (isTest == "ON" && (embOption == "OBJ_TN" || embOption == "VOB_TN" || embOption == "OBJ_TT")){
                separateSources(root, targetMacro, embOption, projectName, false, true);
            }
            addExtraDirs(root, targetMacro, projectName);
        }
        case configureIntegrationTestExecutable(targetMacro, embOption, params): {
            str execType = params[0];
            str isTest = findMacro("BUILD_TEST_CODE", projectName)<0>[0];
            isTest = "ON";
            if((execType == "SEQUENTIAL" || execType == "PARALLEL") && isTest == "ON" && (embOption == "OBJ_TN" || embOption == "VOB_TN" || embOption == "OBJ_TT")){
                separateSources(root, targetMacro, embOption, projectName, false, true);
            }
            addExtraDirs(root, targetMacro, projectName);
        }
        case configureModuleTestExecutable(targetMacro, embOption, params): {
            str execType = params[0];
            str isTest = findMacro("BUILD_TEST_CODE", projectName)<0>[0];
            isTest = "ON";
            if((execType == "SEQUENTIAL" || execType == "PARALLEL") && isTest == "ON" && (embOption == "OBJ_TN" || embOption == "VOB_TN" || embOption == "OBJ_TT")){
                separateSources(root, targetMacro, embOption, projectName, false, true);
            }
            addExtraDirs(root, targetMacro, projectName);
        }
        case configureLibrary(targetMacro, params): {
            str embOption = params[0];
            if(embOption == "OBJ_TN" || embOption == "OBJ_TN_VXWIN" || embOption == "VOB_TN" || embOption == "OBJ_VXWORKS"){
                separateSources(root, targetMacro, embOption, projectName, false, false);
            }
        }
        case configureExecutable(targetMacro, embOption, _): {
            if(embOption == "OBJ_TN" || embOption == "VOB_TN" || embOption == "OBJ_TT"){
                separateSources(root, targetMacro, embOption, projectName, false, false);
            }
        }
        case configureDLL(targetMacro, embOptMacro): {
            str embOption = "";
            if(embOptMacro.sourceFile == "OBJ_TN" || embOptMacro.sourceFile  == "VOB_TN"){
                embOption = embOptMacro.sourceFile;
            }else{
                embOption = findMacro(embOptMacro.sourceFile, projectName)<0>[0];
            }
            if(embOption == "OBJ_TN" || embOption == "VOB_TN"){
                separateSources(root, targetMacro, embOption, projectName, false, false);
            } 
        }
        case configureGuiApp(targetMacro, params): {
            str embOption = params[0];
            if(embOption == "OBJ_TN" || embOption == "VOB_TN"){
                separateSources(root, targetMacro, embOption, projectName, true, false);
            }
        }
        case configureQtApp(targetMacro, params): {
            str embOption = params[0];
            if(embOption == "OBJ_TN" || embOption == "VOB_TN"){
                separateSources(root, targetMacro, embOption, projectName, false, false);
            }
        }
    }
    return isLeaf;
}

tuple[set[loc], set[loc]] parseConfigurations(str targetMacro, str embOption, str projectName, bool isGui){
    set[loc] sourceFiles = {};
    set[loc] headFiles = {};
    str targetName = findMacro(targetMacro, projectName)<0>[0];
    str buildColor = findMacro("BUILD_COLOR", projectName)<0>[0];
    // _SOURCES
    list[loc] found = isGui? [toLocation(x) | x <- findMacro(targetName + "_SOURCES", projectName)<0> + findMacro(targetName + "_" + embOption + "_" + buildColor + "_SOURCES", projectName)<0>] : 
                             [toLocation(x) | x <- findMacro(targetName + "_SOURCES", projectName)<0> + findMacro(targetName + "_" + embOption + "_SOURCES", projectName)<0>];
    for(file <- found){
        if(isFile(file)){
            if(file.extension == "c" || file.extension == "cpp"){
                sourceFiles += convertSinglePathToLower(file);
            }
        }
        else if(isDirectory(file)){
            sourceFiles += convertPathsToLower(find(file, bool(loc l){return l.extension == "c" || l.extension == "cpp";}));
        }
    }
    // _DIRS
    headFiles = {toLocation(x) | x <- findMacro(targetName + "_DIRS", projectName)<0> + findMacro(targetName + "_" + embOption + "_DIRS", projectName)<0>};
    return <sourceFiles, headFiles>;
}

// parse the cmakes linked by the include() function
bool parseIncludeStatement(loc root, str projectName, bool isLeaf, list[loc] skipCmakes, list[loc] targets, loc externalDir, str binPath){
    if(root notin fileToProject<0>){
        fileToProject += (root : projectName);
        cmakeFiles += root;
    }
    iprintln(root);
    if(root in skipCmakes){
        return isLeaf;
    }
    p = parse(root);
	y = implode(p);
    // iprintln(y);
    return parseStatement(root, y, projectName, isLeaf, skipCmakes, targets, externalDir, binPath);
}

// This function is only called by setMapping and setMultiMacMapping. The targetMacro is a plain string, no ${}
set[loc] parseSetStatement(loc root, list[str] paths, str targetMacro, str projectName){
    map[str, set[str]] localMacroValueMap = ();
    int i = 0;
    set[loc] newPathSet = {};
    list[str] entitiesToAdd = [];
    str drive = (root.path[.. 4])[1 ..];
    while(i < size(paths)){
        // exception: PROJECT_BINARY_DIR
        if(paths[i] == "PROJECT_BINARY_DIR" || targetMacro == "SUP_GENERATED_SOURCES_LOCATION" || targetMacro == "SUP_GENERATED_SOURCES_LOCATION_FROM_ROOT"){
            tuple[str, int] res = concatBinDir(paths, projectName, i);
            entitiesToAdd += [res<0>];
            // addPathOrParamToMap(targetMacro, "", [res<0>], projectName);
            loc resLoc = toLocation(res<0>);
            if(isDirectory(resLoc) || isFile(resLoc)){
                newPathSet += resLoc;
            }
            i = res<1>;
            continue;
        }
        if(i + 1 < size(paths) && /^\// !:= paths[i] && /^\// := paths[i + 1]){ // ${prefix}../../p/a/t/h; this case requires the $ pattern
            tuple[list[str] myStr, bool myBool] findRes = findMacro(paths[i], projectName);
            list[str] foundEntity = findRes.myStr;
            if(!isEmpty(foundEntity) && findRes.myBool){
                for(entity <- foundEntity){
                    str newPath = removeDot(paths[i+1], entity, root);
                    if(/\.\./ := newPath){
                        newPath = removeDoubleDots(toLocation(newPath)).uri;
                    }
                    entitiesToAdd += [newPath];
                    // addPathOrParamToMap(targetMacro, "", [newPath], projectName);
                    loc newLoc = toLocation(newPath);
                    if(isDirectory(newLoc) || isFile(newLoc)){
                        newPathSet += newLoc;
                    }
                }
                i += 2;
            }else{  // else: foundEntity is empty --> already processed at findMacro
                i += 1;
            }
        }else if(/^\.\.\// := paths[i] || /^\// := paths[i]){ // ../path, /path
            str newPath = removeDot(paths[i], "", root);
            entitiesToAdd += [newPath];
            // addPathOrParamToMap(targetMacro, "", [newPath], projectName);
            loc newLoc = toLocation(newPath);
            if(isDirectory(newLoc) || isFile(newLoc)){
                newPathSet += newLoc;
            }
            i += 1;
        }else if(/^\// !:= paths[i] && (/\.h$/ := paths[i] || /\.hpp$/ := paths[i] || /\.c$/ := paths[i] || /\.cpp$/ := paths[i] || (/\// := paths[i] && /^<drive>/i !:= paths[i]))){ // file (.h, .hpp) or p/a/t/h, exclude: string that is not .h and .hpp and has no "/"
            str newPath = root.parent.uri + "/" + paths[i];
            entitiesToAdd += [newPath];
            // addPathOrParamToMap(targetMacro, "", [newPath], projectName);
            loc newLoc = toLocation(newPath);
            if(isDirectory(newLoc) || isFile(newLoc)){
                newPathSet += newLoc;
            }
            i += 1;
        }else{ // ${} without suffix path or a single parameter
            tuple[list[str], bool] findRes = findMacro(paths[i], projectName);
            list[str] foundEntity = toList(toSet(findRes<0>));
            if(findRes<1> == true){     // convert foundEntity to set because it may include duplicated PROJECT_SOURCE_DIR from both macroPathByProject and macroVariableByProject
                for(entity <- foundEntity){
                    entitiesToAdd += [entity];
                    // addPathOrParamToMap(targetMacro, "", [entity], projectName);
                    loc newLoc = toLocation(entity);
                    if(isDirectory(newLoc) || isFile(newLoc)){
                        newPathSet += newLoc;
                    }
                }
            }else{  // if the macro is not found, then paths[i] is regarded as a single parameter instead of ${}, even though some are ${}
                str path = paths[i];
                if(/<drive>/i := paths[i]){
                    path = "file:///" + paths[i];
                }
                entitiesToAdd += [path];
                // addPathOrParamToMap(targetMacro, "", [path], projectName);
                loc newLoc = toLocation(path);
                if(isDirectory(newLoc) || isFile(newLoc)){
                    newPathSet += newLoc;
                }
            }
            i += 1;
        }
    }
    addPathOrParamToMap(targetMacro, "", entitiesToAdd, projectName);
    return newPathSet;
}

// CMakeListsMSVC: the definition of configureClassTestExecutable, configureModuleTestExecutable, configureIntegrationTestExecutable add PosGen/infra to _DIRS
void addExtraDirs(loc root,  str targetMacro, str projectName){
    // in : set(${TARGET_NAME}_DIRS ${${TARGET_NAME}_DIRS} ${POS_GEN_PATH}/infra)
    str targetName = findMacro(targetMacro, projectName)<0>[0];
    str posGenPath = findMacro("POS_GEN_PATH", projectName)<0>[0];
    loc posGenLoc = toLocation(posGenPath + "/infra");
    if(exists(posGenLoc)){
        macroPathByProject[projectName][targetName + "_DIRS"] += posGenPath + "/infra";
        cmakeToIncludePath = addSetValueToMap(root, {posGenLoc}, cmakeToIncludePath);
        // cmakeToSource = addSetValueToMap(root, convertPathsToLower(find(posGenLoc, bool(loc l){return l.extension == "c" || l.extension == "cpp";})), cmakeToSource);
    }
}

set[str] concatPaths(loc root, list[str] paths, str projectName, loc externalDir){
    int i = 0;
    set[str] pathList = {};
    while(i < size(paths)){
        if(paths[i] == ""){
            i += 1;
            continue;
        }
        if(paths[i] == "PROJECT_BINARY_DIR"){
            tuple[str, int] res = concatBinDir(paths, projectName, i);
            if(isDirectory(toLocation(res<0>)) || isFile(toLocation(res<0>))){
                pathList += res<0>;
            }
            i = res<1>;
            continue;
        }
        // ${macro}/path, $(macro)/../../path, also parameters: $(macro)_SUFFIX; excluded: ${macro} \n /../sourceFile.cpp
        if(i + 1 < size(paths) && /^\// !:= paths[i] && /^\// := paths[i + 1]){
            list[str] foundEntity = [];
            if(paths[i] == "CMAKE_CURRENT_SOURCE_DIR"){
                foundEntity += root.parent.uri;
            }
            else{
                foundEntity = toList(toSet(findMacro(paths[i], projectName)<0>));
            }
            foundEntity = [e | e <- foundEntity, (isDirectory(toLocation(e)) || isFile(toLocation(e)))];
            // if(size(foundEntity) > 1){
            //     iprintln("Macro <paths[i]> has multiple mappings (source: concatPaths)");
            // }
            bool isExcludeCase = false;
            if(!isEmpty(foundEntity)){
                for(entity <- foundEntity){
                    str newPath = removeDot(paths[i + 1], entity, root);
                    if(!isDirectory(toLocation(newPath)) && !isFile(toLocation(newPath)) && (/\.cpp$/ := paths[i + 1] || /\.c$/ := paths[i + 1])){
                        isExcludeCase = true;
                    }else{
                        if(exists(toLocation(newPath))){
                            pathList += newPath;
                        }
                    }
                }
                if(isExcludeCase == true){
                    i += 1;
                }else{
                    i += 2;
                }
            }else{
                // iprintln("Macro <paths[i]> not found or it is not a macro. (source: concatPaths_1)");
                i += 1;
            }
        }
        // ../path, /path
        else if(/^\.\.\// := paths[i] || /^\// := paths[i]){
            pathList += removeDot(paths[i], "", root);
            i += 1;
        }
        // file (.h, .hpp), or contain "/" but not at the begining: p/a/t/h
        else if(/^\// !:= paths[i] && (/\.h$/ := paths[i] || /\.hpp$/ := paths[i] ||  /\// := paths[i])){
            pathList += root.parent.uri + "/" + paths[i];
            i += 1;
        }
        // ${macro}, macro
        else if(/\// !:= paths[i] && /^[A-Z0-9_]+$/ := paths[i] && paths[i] != "AIO"){  // Exception: AIO is not a macro, it is a string
            set[str] foundEntity = toSet(findMacro(paths[i], projectName)<0>);
            foundEntity = {e | e <- foundEntity, (isDirectory(toLocation(e)) || isFile(toLocation(e)))};
            // if(size(foundEntity) > 1){
            //     iprintln("Macro <paths[i]> has multiple mappings (source: concatPaths)");
            // }
            if(!isEmpty(foundEntity)){
                pathList += foundEntity;
            }else if(paths[i] == "PLATFORM_DIRS"){  // definition for ${PLATFORM_DIRS} cannot be found, but it is used for include path
                str ext = externalDir.uri + "/Philips.3rdParty.VxWorks7sr630.VxWin/vsb_vxwin7/krnl/h/public";
                pathList += ext + toStrSet(toLocation(ext).ls);
                ext = externalDir.uri + "/Philips.3rdParty.VxWorks7sr630.VxWin/vsb_vxwin7/usr/h/public";
                pathList += ext + toStrSet(toLocation(ext).ls);
                ext = externalDir.uri + "/" + "/Philips.3rdParty.VxWorks54.LucIo/VxWorks5x/LUC_V4/inc";
                pathList += ext + toStrSet(toLocation(ext).ls);
            }
            i += 1;
        } else{ // for the files/directories that are not for include paths, e.g. cpp/c files; or macros specified in special pattern
            tuple[list[str], bool] findRes = findMacro(paths[i], projectName);
            set[str] foundEntity = toSet(findRes<0>);    // for special macros, e.g. SOURCES_files_Source_Files__GenericSrc
            foundEntity = {e | e <- foundEntity, (isDirectory(toLocation(e)) || isFile(toLocation(e)))};
            if(findRes<1> == true){
                pathList += foundEntity;
            }else{
                pathList += root.parent.uri + "/" + paths[i];
            }
            i += 1;
        }
    }
    return pathList;
}

// concat ${}/str/${}...
tuple[str, int] concatBinDir(list[str] paths, str projectName, int i){  // dir can be both path and parameter (set (SUP_GENERATED_SOURCES_LOCATION_FROM_ROOT BuildPos/${TARGET_NAME}))
    str binDir = "";
    while(i < size(paths)){
        // exception: UnitRootDir
        if((/^_/ !:= paths[i] && /\// !:= paths[i] && /^[A-Z_]+$/ := paths[i]) || paths[i] == "UnitRootDir"){ // ${macro}
            list[str] found = findMacro(paths[i], projectName)<0>;
            if(isEmpty(found)){
                iprintln("Value for <paths[i]> not found");
            }else{
                binDir += found[0];
            }
        }else{  // plain string
            binDir += paths[i];
        }
        if(/\.dir/ := paths[i]){
            return <binDir, i + 1>;
        }
        i += 1;
    }
    return <binDir, i + 1>;
}

// split a set of paths(directories) into 3 parts: include path(headers), stdLib(externals), source files 
// target can either be target macro (setList) or plain string (setMapping, setMultiMacMapping)
void splitPathSet(loc root, str target, set[loc] paths, list[loc] targets, loc externalDir){
    paths = {x | x <- paths, (isDirectory(x) || isFile(x))};
    if((/Header_Files/ := target || /HEADER/ := target || /_DIRS$/ := target || /^SOURCE_HeaderFiles/ := target || /Headers$/ := target || /HEADERS$/ := target) && target != "SourceFiles_DIRS"){
        set[loc] stdlib = {};
        set[loc] src = {};
        for(dir <- paths){
            if(dir == externalDir || isLexicallyLess(dir, externalDir)){    // paths from EXTERNALS and its children: stdlib for ClaiR
                stdlib += dir;
            }
            else if(/_DIRS$/ := target){
                if(isFile(dir) && (dir.extension == "c" || dir.extension == "cpp")){
                    src += dir;
                }else{
                    // check if it is in PosXXX, then find all srcs
                    if(/src/i := dir.path && isChildPath(targets, dir)){
                        set[loc] found = find(dir, bool (loc l) { return l.extension == "cpp" || l.extension == "c"; });
                        for(sourcePath <- found){
                            // sourcePath = removeDoubleDots(sourcePath);
                            if(isChildPath(targets, sourcePath)){
                                src += sourcePath;
                            }
                        }
                    }
                }
            }
        }
        cmakeToStdlib = addSetValueToMap(root, stdlib, cmakeToStdlib);
        cmakeToIncludePath = addSetValueToMap(root, paths - stdlib, cmakeToIncludePath);
        cmakeToSource = addSetValueToMap(root, convertPathsToLower(src), cmakeToSource);
    }
    if((/^SOURCES_files_Source/ := target || /^SOURCES_Source/ := target || /_SOURCES$/ := target || /^SOURCE_SourceFiles/ := target || /CPP_FILES/ := target || /_Sources$/ := target || "SOURCES_Generated_Files" == target) && /HEADER/ !:= target){
        set[loc] src = {};
        set[loc] inc = {};
        set[loc] stdlib = {};
        for(dir <- paths){
            // SOURCES may also include some EXTERNALs
            if(dir == externalDir || isLexicallyLess(dir, externalDir)){
                stdlib += dir;
                continue;
            }
            if(dir.extension == "h" || dir.extension == "hpp" || (isDirectory(dir) && dir.file != "src")){
                inc += dir;        
            }
            set[loc] foundSrc = find(dir, bool (loc l) { return l.extension == "cpp" || l.extension == "c"; });
            src += foundSrc;
            if(/_SOURCES$/ := target){
                cmakeToKeySource = addSetToMap(cmakeToKeySource, root, foundSrc);
            }
        }
        cmakeToStdlib = addSetValueToMap(root, stdlib, cmakeToStdlib);
        cmakeToSource = addSetValueToMap(root, convertPathsToLower(src), cmakeToSource);    // convert src paths to lower case to avoid failed key-matching in map
        cmakeToIncludePath = addSetValueToMap(root, inc, cmakeToIncludePath);
    }
}

map[loc, set[loc]] addSetValueToMap(loc key, set[loc] valueSet, map[loc, set[loc]] targetMap){
    if(key in targetMap<0>){
        targetMap[key] += valueSet;
    }else{
        targetMap += (key : valueSet);
    }
    return targetMap;
}

tuple[list[str], bool] findMacro(str key, str projectName){
    tuple[list[str], bool] findPaths = findMacroPath(key, projectName);
    tuple[list[str], bool] findParameters = findMacroParameter(key, projectName);
        // some items are both in macroVariableByProject and macroPathByProject, they all are paths, remove the duplicates or it may cause errors
    if(findPaths<1> == false && findParameters<1> == true){
        return findParameters;
    }else if(findPaths<1> == true && findParameters<1> == false){
        return findPaths;
    }else if(findPaths<1> == true && findParameters<1> == true){
        return <toList(toSet(findPaths<0> + findParameters<0>)), true>;
    }else{
        return <[], false>;
    }
}

tuple[list[str], bool] findMacroPath(str key, str projectName){
    // first search the local macro definitions
    if(key in macroPathByProject[projectName]){
        return <macroPathByProject[projectName][key], true>;
    }else{
        // if not found, then search the parent node until to the root
        str name = projectName;
        while(name in childToParent<0> && name != "ROOT"){
            name = childToParent[name];
            if(key in macroPathByProject[name]){
                return <macroPathByProject[name][key], true>;
            }
        }
        // if it is the root node but still not found
        if(key == "ON" || key == "OFF" || key == "STATIC"){ // some exceptions
            return <[key], true>;
        }else{
            return <[], false>;
        }

    }
}

tuple[list[str], bool] findMacroParameter(str key, str projectName){
    if(key in macroVariableByProject[projectName]){
        if(!isEmpty(macroVariableByProject[projectName][key])){
            return <[macroVariableByProject[projectName][key][-1]], true>;     // always get the newest one parameter value by using [-1]
        }
        else{
            return <macroVariableByProject[projectName][key], true>;
        }
    }else{
        // if not found, then search the parent node until to the root
        str name = projectName;
        while(name in childToParent<0> && name != "ROOT"){
            name = childToParent[name];
            if(key in macroVariableByProject[name]){
                return <[macroVariableByProject[name][key][-1]], true>;
            }
        }
        return <[], false>;
    }
}

// ${macro}../../p/a/t/h, ${macro}/p/a/t/h...
str removeDot(str path, str macroPath, loc root){
    list[int] idxs = findAll(path, "../");
    if(size(idxs) == 0){
        return macroPath != ""? macroPath + path : root.parent.uri + path;
    }
    int parentCount = size(idxs);
    loc prefix = |unknown:///|;
    if(macroPath != ""){
        prefix = toLocation(macroPath);
    }else{
        prefix = root.parent;
    }
    while(parentCount > 0){
        prefix = prefix.parent;
        parentCount -= 1;
    }
    return prefix.uri + "/" + path[idxs[-1] +3 ..];
}

loc removeDoubleDots(loc target){
    str tgrStr = target.uri;
    int index = findFirst(tgrStr, "..");
    while(index != -1){
        list[int] slashIndices = findAll(target.uri, "/");
        int j = indexOf(slashIndices, index - 1);
        tgrStr = j + 1 == size(slashIndices)? tgrStr[.. slashIndices[j - 1]] : tgrStr[.. slashIndices[j - 1]] + tgrStr[slashIndices[j + 1]..];
        index = findFirst(tgrStr, "..");
    }
    return toLocation(tgrStr);
}

// add parameters to macroVariableByProject, add paths to macroPathByProject
void addPathOrParamToMap(str macroKey, str typ, list[str] entities, str projectName){
    if(isEmpty(entities)){  // in some cases, the macro valus is []
        macroVariableByProject[projectName] += (macroKey + typ : []);
        macroPathByProject[projectName] += (macroKey + typ : []);
    }else{
        for(e <- entities){
            if(!isDirectory(toLocation(e)) && !isFile(toLocation(e)) && /^file:/ !:= e){
                if((macroKey + typ) in macroVariableByProject[projectName]){
                    // parameter should have only one value, but we use a list to keep the history values here. When fetch the parameter value, always pick the newest one
                    macroVariableByProject[projectName][macroKey + typ] += [e];
                }else{
                    macroVariableByProject[projectName] += (macroKey + typ : [e]);
                }                    
                entities -= e;
            }
        }
        if(!isEmpty(entities)){
            macroPathByProject[projectName] += (macroKey + typ : entities);
        }
    }
}

void separateSources(loc root, str targetMacro, str embOption, str projectName, bool isGui, bool isTest){
    tuple[set[loc], set[loc]] res = parseConfigurations(targetMacro, embOption, projectName, isGui);
    set[loc] sourcePaths = res<0>;
    set[loc] headPaths = res<1>;
    if(isTest){
        sourceTest += sourcePaths;
        sourceTestByCmake = addSetToMap(sourceTestByCmake, root, sourcePaths);
        headerTestByCmake = addSetToMap(headerTestByCmake, root, headPaths);
    }else{
        sourceProduction += sourcePaths;
        sourceProductionByCmake = addSetToMap(sourceProductionByCmake, root, sourcePaths);
        headerProductionByCmake = addSetToMap(headerProductionByCmake, root, headPaths);
    }
    if(embOption == "OBJ_VXWORKS"){
        str macroVal = findMacro("TARGET_NAME", projectName)<0>[0];
        set[loc] targets = {toLocation(x) | x <- findMacro(macroVal + "_SOURCES", projectName)<0>};
        sourceVxworks += {*convertPathsToLower(find(x, bool(loc l){return l.extension == "c" || l.extension == "cpp";})) | x <- targets};
        headerVxworks += {*convertPathsToLower(find(x, bool(loc l){return l.extension == "h" || l.extension == "hpp";})) | x <- targets};
    }
}

list[loc] missedFiles(list[loc] targetsOriginal, rel[loc, loc] sourceToCmakeRel){
    list[loc] diff = [];
    list[loc] sourceFileListTrue = getTargetList(targetsOriginal, true);
    list[loc] headerListTrue = getTargetList(targetsOriginal, false); 
    sourceFileListTrue = [toLocation(toLowerCase(x.uri)) | x <- sourceFileListTrue];
    headerListTrue = [toLocation(toLowerCase(x.uri)) | x <- headerListTrue];
    list[loc] soureFileListGenerated = toList({toLocation(toLowerCase(x.uri)) | x <- sourceToCmakeRel<0>});
    iprintln("Number of detected source files (duplicates removed): <size(soureFileListGenerated)>");
    iprintln("Number of source files (true value): <size(sourceFileListTrue)>");
    iprintln("Number of unfound source files: <size(sourceFileListTrue) - size(soureFileListGenerated)>");
    diff = sourceFileListTrue - soureFileListGenerated;
    return diff;
}