module Parser

import IO;
import Set;
import List;
import Relation;
import lang::cpp::M3;


// Alpha modules
import utils::Common;
import utils::Constants;
import utils::Persistence;
import utils::Types;

private loc inputFolderAbsolutePath;
private bool composeModels = true;
private bool verbose = false;
private bool saveFilesAsJson = true;
private bool saveUnresolvedIncludes = false;


void main(str moduleName = "") {
    
    Configuration loadedConfig = loadConfiguration();

    inputFolderAbsolutePath = |file:///| + loadedConfig.inputFolderAbsolutePath;
    saveFilesAsJson = loadedConfig.saveFilesAsJson;
    composeModels = loadedConfig.composeModels;
    verbose = loadedConfig.verbose;
    saveUnresolvedIncludes = loadedConfig.saveUnresolvedIncludes;

    if(moduleName == "") {
        parseModuleListToComposedM3();
    }
    else {
        parseCppListToM3(moduleName);
    }
}

public void parseCppListToM3(str m3FileName) {
    list[loc] cppFiles = loadFilePathsFromFile(inputFolderAbsolutePath + CPP_FILES_LIST_FILE);
    processCppFiles(cppFiles, m3FileName);
}

public void parseModuleListToComposedM3() {
    list[loc] listsOfInputFilesForModules = loadFilePathsFromFile(inputFolderAbsolutePath + MODULES_FILES_LIST_FILE);

    for (loc listOfCppFilesInModule <- listsOfInputFilesForModules) {
        str moduleName = getNameFromFilePath(listOfCppFilesInModule);
        println("Processing module <moduleName>");
        list[loc] cppFiles = loadFilePathsFromFile(listOfCppFilesInModule);
        processCppFiles(cppFiles, moduleName);
    }  
}

// Process a list of C++ files
private void processCppFiles(list[loc] cppFilePaths, str appName) {
    set[M3] M3Models = {};

    for (loc cppFilePath <- cppFilePaths) {
        str fileName = getNameFromFilePath(cppFilePath);
        extractedModels = extractModelsFromCppFile(cppFilePath);
        M3Models += extractedModels[0];
        saveExtractedModelsToDisk(extractedModels, fileName, saveFilesAsJson);
        
        if(saveUnresolvedIncludes) {
            outputUnresolvedIncludes(fileName, extractedModels[0].includeResolution);
        }
        
    }
    if (composeModels) {
        M3 composedModels = composeCppM3(|file:///|, M3Models);
        saveComposedExtractedM3ModelsAsJSON(composedModels, appName);
    }
}

private void outputUnresolvedIncludes(str fileName, rel[loc directive, loc resolved] includeResolution) {
    rel[loc directive, loc resolved] unresolvedIncludes = rangeR(includeResolution, {|unresolved:///|});
    listOfUnresolvedIncludes = toList(unresolvedIncludes);

    list[str] UnresolvedIncludesAsStrings = [];

    for(tuple[loc directive, loc resolved] binaryRelation <- listOfUnresolvedIncludes) {
        UnresolvedIncludesAsStrings = UnresolvedIncludesAsStrings + binaryRelation.directive.path;
    }

    saveListToFile(fileName, UnresolvedIncludesAsStrings);
}

private ModelContainer extractModelsFromCppFile(loc filePath){
    list[loc] includeFiles = loadFilePathsFromFile(inputFolderAbsolutePath + INCLUDE_FILES_LIST_LOC);
    list[loc] stdLibFiles = loadFilePathsFromFile(inputFolderAbsolutePath + STD_LIBS_LIST_LOC);
    
    if(verbose) {
        for(loc includeFile <- includeFiles) {
            println(includeFile);
        }

        for(loc stdLibFile <- stdLibFiles) {
            println(stdLibFile);
        }
    }

    ModelContainer extractedModels = createM3AndAstFromCppFile(filePath, stdLib = stdLibFiles, includeDirs = includeFiles);
    return extractedModels;
}