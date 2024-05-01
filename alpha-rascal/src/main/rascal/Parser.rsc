module Parser

import IO;
import Set;
import Relation;
import Location;
// import lang::cpp::AST;
import lang::cpp::M3;


// Alpha modules
import utils::Common;
import utils::Constants;
import utils::Persistence;
import utils::Types;

public void parseToComposedM3(str appName, bool saveAsJson, bool verbose, bool outputExtraData) {
    list[loc] cppFiles = readFilePathsFromFile(CPP_FILES_LIST_LOC);
    processCppFiles(cppFiles, appName, saveAsJson, verbose, outputExtraData);
}

public void processModelsFromDisk() {
    list[ClassEntity] loadedListOfClassEntities = loadExtractedModelsFromDisk();
    int modelCounter = 0;
    
    println("Processing <size(loadedListOfClassEntities)> classEntities");

    println("Processed <modelCounter> saved models and successfully created call graphs.");
}

// Process a list of C++ files
private void processCppFiles(list[loc] cppFilePaths, str appName, bool saveAsJson, bool verbose, bool outputExtraData) {
    set[M3] M3Models = {};

    for (loc cppFilePath <- cppFilePaths) {
        str className = getClassNameFromFilePath(cppFilePath);
        extractedModels = extractModelsFromCppFile(cppFilePath, verbose);
        M3Models += extractedModels[0];
        saveExtractedModelsToDisk(extractedModels, className, saveAsJson);
        
        if(outputExtraData) {
            outputUnresolvedIncludes(className, extractedModels[0].includeResolution);
        }
        
    }

    M3 composedModels = composeCppM3(|file:///|, M3Models);
    saveComposedExtractedM3ModelsAsJSON(composedModels, appName);
}

private void outputUnresolvedIncludes(str className, rel[loc directive, loc resolved] includeResolution) {
    rel[loc directive, loc resolved] unresolvedIncludes = rangeR(includeResolution, {|unresolved:///|});
    listOfUnresolvedIncludes = toList(unresolvedIncludes);

    list[str] UnresolvedIncludesAsStrings = [];

    for(tuple[loc directive, loc resolved] binaryRelation <- listOfUnresolvedIncludes) {
        UnresolvedIncludesAsStrings = UnresolvedIncludesAsStrings + binaryRelation.directive.path;
    }

    writeListToFile(className, UnresolvedIncludesAsStrings);
}

private ModelContainer extractModelsFromCppFile(loc filePath, bool verbose){
    list[loc] includeFiles = readFilePathsFromFile(INCLUDE_FILES_LIST_LOC);
    list[loc] stdLibFiles = readFilePathsFromFile(STD_LIBS_LIST_LOC);
    
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

// void processModelsFromDisk(list[ModelContainer] listOfModelContainers) {
//     for(ModelContainer modelContainer <- modelsCollection) {
//         rel[loc caller, loc callee] callGraph = extractCallGraph(models[1]);
//         // for (entry <- callGraph){
//         //     println("<entry[0]>  -\> <entry[1]>");
//         // }
//         writeValueToTextFile(callGraph);
//     }
// }

// void testReadingModels() {
//     loadedAST = readASTFromFile(|file:///C:/Development/TF/Alpha/alpha-rascal/models/AST/exampleAST.bin|);
//     loadedM3 = readM3FromFile(|file:///C:/Development/TF/Alpha/alpha-rascal/models/M3/exampleM3.bin|);
//     tuple[M3 loadedM3, Declaration loadedAST] models = <loadedM3, loadedAST>;
//     list[tuple[M3, Declaration]] modelsCollection = [models];
//     analyzeModelsFromDisk(modelsCollection);
// }

// int main(int testArgument=0) {
//     loc filePathsFile = |file:///C:/Development/TF/Alpha/alpha-rascal/cpp-files.txt|;
//     list[loc] cppFiles = readFilePathsFromFile(filePathsFile);
//     extractModelsToDisk(cppFiles);
//     //processCppFiles(cppFiles);
//     return testArgument;
// }
