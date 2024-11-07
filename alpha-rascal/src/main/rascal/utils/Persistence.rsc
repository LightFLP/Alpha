module utils::Persistence

import IO;
import Exception;
import List;
import Set;
import util::FileSystem;
import ValueIO;
import lang::cpp::M3;
import lang::json::IO;

// Alpha modules
import utils::Common;
import utils::Constants;
import utils::Types;

public Configuration loadConfiguration(){
    Configuration defaultConfig = configuration("C:/Development/TF/Alpha/alpha-rascal/input", true, true, false, false);
    loc configurationLoc = |cwd:///config.json|;

    try {
        println("Loading config file");
        Configuration loadedConfig = readJSON(#Configuration, configurationLoc);
        println("Successfully loaded config file");

        return loadedConfig;
    } catch IO(msg): {
        println("[ERROR] Error loading config.json. Default configuration will be used.");
        println("Error message: <msg>");    
    }
    return defaultConfig;
}

public void saveListToFile(str translationUnit, list[str] listToWrite) {
    writeFileLines(|cwd:///| + MODELS_UNRESOLVED_FOLDER + "<translationUnit>-unresolved-includes.txt", listToWrite);
}

public void saveExtractedModelsToDisk(ModelContainer extractedModels, str className, bool saveAsJSon) {
    if(saveAsJSon) {
        saveExtractedM3ModelsAsJSON(extractedModels, className);
    }else{
        saveExtractedModelsAsBinaryFile(extractedModels, className);
    }
}

public void saveExtractedM3ModelsAsJSON(ModelContainer extractedModels, str className) {
    try {
        writeJSON(|cwd:///| + MODELS_FOLDER + "<className>.json", extractedModels[0]);
        println("Successfully wrote <className>.json");
    } catch IO(msg) : {
        println("[ERROR] Error writing <className>.json: <msg> ");
    }
}

public void saveComposedExtractedM3ModelsAsJSON(M3 composedM3Models, str appName) {
    try {
        writeJSON(|cwd:///| + MODELS_COMPOSED_FOLDER + "<appName>.json", composedM3Models);
        println("Successfully wrote <appName>.json");
    } catch IO(msg) : {
        println("[ERROR] Error writing <appName>.json: <msg> ");
    }
}

// Function to save a ModelContainer to a file.
private void saveExtractedModelsAsBinaryFile(value val, str className) {
    try {
        writeBinaryValueFile(|cwd:///| + MODELS_FOLDER + "<className>.bin", val);
        println("Successfully wrote <className>.bin");
    } catch IO(msg) : {
        println("[ERROR] Error writing <className>.bin: <msg> ");
    }
}

// load file paths from a text file
public list[loc] loadFilePathsFromFile(loc filePath) {
    list[str] fileLines = readFileLines(filePath);
    return [ |file:///| + line | str line <- fileLines ];
}

public list[ClassEntity] loadExtractedModelsFromDisk() {
    println("Loading extracted models from disk");

    set[loc] pathsOfModels = files(|cwd:///| + MODELS_FOLDER);

    println("Found <Set::size(pathsOfModels)> extracted models from disk");

    list[ClassEntity] listOfClassEntities = [];

    for(loc modelsPath <- pathsOfModels) {
        str className = getNameFromFilePath(modelsPath);
        ModelContainer modelContainer = loadExtractedModelsFromBinaryFile(modelsPath);
        ClassEntity tempClassEntity = classEntity(className, modelContainer);
        listOfClassEntities = listOfClassEntities + tempClassEntity;
    }

    return listOfClassEntities;    
}

// Function to read a ModelContainer from a file.
private ModelContainer loadExtractedModelsFromBinaryFile(loc file) {
    ModelContainer loadedModelContainer = readBinaryValueFile(#ModelContainer, file);

    return loadedModelContainer;
}