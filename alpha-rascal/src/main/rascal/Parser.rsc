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

// Configuration variables
private loc inputFolderAbsolutePath;
private bool composeModels = true;
private bool verbose = false;
private bool saveFilesAsJson = true;
private bool saveUnresolvedIncludes = false;


/**
 * Entry point of the module. Loads the configuration, sets up processing flags, 
 * and initiates parsing of either a specific module or a default module list.
 * 
 * @param moduleName optional name of the module to process; if empty, all modules are processed.
 */
void main(str moduleName = "") {
    
    Configuration loadedConfig = loadConfiguration();

    inputFolderAbsolutePath = |file:///| + loadedConfig.inputFolderAbsolutePath;
    saveFilesAsJson = loadedConfig.saveFilesAsJson;
    composeModels = loadedConfig.composeModels;
    verbose = loadedConfig.verbose;
    saveUnresolvedIncludes = loadedConfig.saveUnresolvedIncludes;

    println("[CONFIG_VALUE] inputFolderAbsolutePath: <inputFolderAbsolutePath>");
    println("[CONFIG_VALUE] saveFilesAsJson: <saveFilesAsJson>");
    println("[CONFIG_VALUE] composeModels: <composeModels>");
    println("[CONFIG_VALUE] verbose: <verbose>");
    println("[CONFIG_VALUE] saveUnresolvedIncludes: <saveUnresolvedIncludes>");

    if(moduleName == "") {
        parseModuleListToComposedM3();
    }
    else {
        parseCppListToM3(moduleName);
    }
}

/**
 * Parses a list of C++ files for a specified module and extracts their M3 models.
 * 
 * @param m3FileName name of the output file for the extracted M3 model.
 */
public void parseCppListToM3(str m3FileName) {
    list[loc] cppFiles = loadFilePathsFromFile(inputFolderAbsolutePath + CPP_FILES_LIST_FILE);
    processCppFiles(cppFiles, m3FileName);
}

/**
 * Parses a predefined list of modules, extracting and optionally composing M3 models for each module.
 */
public void parseModuleListToComposedM3() {
    list[loc] listsOfInputFilesForModules = loadFilePathsFromFile(inputFolderAbsolutePath + MODULES_FILES_LIST_FILE);

    for (loc listOfCppFilesInModule <- listsOfInputFilesForModules) {
        str moduleName = getNameFromFilePath(listOfCppFilesInModule);
        println("Processing module <moduleName>");
        list[loc] cppFiles = loadFilePathsFromFile(listOfCppFilesInModule);
        processCppFiles(cppFiles, moduleName);
    }  
}

/**
 * Processes a list of C++ files by extracting M3 models, saving the models as JSON if enabled,
 * and optionally composing all models into a single M3 model.
 * 
 * @param cppFilePaths list of locations of C++ source files to process.
 * @param appName name of the application/module for saving the composed M3 model.
 */
private void processCppFiles(list[loc] cppFilePaths, str appName) {
    set[M3] M3Models = {};
    list[loc] includeFiles = loadFilePathsFromFile(inputFolderAbsolutePath + INCLUDE_FILES_LIST_LOC);
    list[loc] stdLibFiles = loadFilePathsFromFile(inputFolderAbsolutePath + STD_LIBS_LIST_LOC);
    
    if(verbose) {
        println("Using following includeDirs:");
        for(loc includeFile <- includeFiles) {
            println(includeFile);
        }

        println("Using following stdLibs:");
        for(loc stdLibFile <- stdLibFiles) {
            println(stdLibFile);
        }
    }

    for (loc cppFilePath <- cppFilePaths) {
        str fileName = getNameFromFilePath(cppFilePath);
        extractedModels = extractModelsFromCppFile(cppFilePath, includeFiles, stdLibFiles);
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

/**
 * Outputs unresolved include directives to a file for further inspection.
 * 
 * @param fileName name of the C++ source file being processed.
 * @param includeResolution relation mapping include directives to their resolved paths.
 */
private void outputUnresolvedIncludes(str fileName, rel[loc directive, loc resolved] includeResolution) {
    rel[loc directive, loc resolved] unresolvedIncludes = rangeR(includeResolution, {|unresolved:///|});
    listOfUnresolvedIncludes = toList(unresolvedIncludes);

    list[str] UnresolvedIncludesAsStrings = [];

    for(tuple[loc directive, loc resolved] binaryRelation <- listOfUnresolvedIncludes) {
        UnresolvedIncludesAsStrings = UnresolvedIncludesAsStrings + binaryRelation.directive.path;
    }

    saveListToFile(fileName, UnresolvedIncludesAsStrings);
}

/**
 * Extracts M3 and AST models from a single C++ source file. 
 * Includes verbose output of include directories and standard library files if enabled.
 * 
 * @param filePath location of the C++ file to process.
 * @param includeFiles list of folders containing the C++ included headers to process.
 * @param stdLibFiles list of folders containing the standard libraries used in the analysed system.
 * @return ModelContainer holding the extracted M3 and AST models for the given C++ file.
 */
private ModelContainer extractModelsFromCppFile(loc filePath, list[loc] includeFiles, list[loc] stdLibFiles){
    ModelContainer extractedModels = createM3AndAstFromCppFile(filePath, stdLib = stdLibFiles, includeDirs = includeFiles);

    return extractedModels;
}