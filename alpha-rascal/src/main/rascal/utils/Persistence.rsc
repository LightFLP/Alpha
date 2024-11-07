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

/**
 * Loads the configuration from a JSON file if it exists; otherwise, returns a default configuration.
 * 
 * @return a `Configuration` instance containing the settings loaded from `config.json` or defaults.
 */
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

/**
 * Saves a list of strings to a file, each as a new line.
 * 
 * @param translationUnit name of the translation unit (used in the file naming).
 * @param listToWrite the list of strings to save.
 */
public void saveListToFile(str translationUnit, list[str] listToWrite) {
    writeFileLines(|cwd:///| + MODELS_UNRESOLVED_FOLDER + "<translationUnit>-unresolved-includes.txt", listToWrite);
}

/**
 * Saves extracted models to disk, either as JSON or as a binary file based on configuration.
 * 
 * @param extractedModels container holding the extracted models.
 * @param className name of the class or module to use as the file name.
 * @param saveAsJSon boolean flag indicating whether to save as JSON (true) or binary (false).
 */
public void saveExtractedModelsToDisk(ModelContainer extractedModels, str className, bool saveAsJSon) {
    if(saveAsJSon) {
        saveExtractedM3ModelsAsJSON(extractedModels, className);
    }else{
        saveExtractedModelsAsBinaryFile(extractedModels, className);
    }
}

/**
 * Saves an extracted M3 model to disk as a JSON file.
 * 
 * @param extractedModels container holding the extracted models.
 * @param className name of the class or module to use as the file name.
 */
public void saveExtractedM3ModelsAsJSON(ModelContainer extractedModels, str className) {
    try {
        writeJSON(|cwd:///| + MODELS_FOLDER + "<className>.json", extractedModels[0]);
        println("Successfully wrote <className>.json");
    } catch IO(msg) : {
        println("[ERROR] Error writing <className>.json: <msg> ");
    }
}

/**
 * Saves a composed M3 model to disk as a JSON file.
 * 
 * @param composedM3Models the composed M3 model to save.
 * @param appName name of the application/module to use as the file name.
 */
public void saveComposedExtractedM3ModelsAsJSON(M3 composedM3Models, str appName) {
    try {
        writeJSON(|cwd:///| + MODELS_COMPOSED_FOLDER + "<appName>.json", composedM3Models);
        println("Successfully wrote <appName>.json");
    } catch IO(msg) : {
        println("[ERROR] Error writing <appName>.json: <msg> ");
    }
}

/**
 * Saves a ModelContainer to disk as a binary file.
 * 
 * @param val the ModelContainer to save.
 * @param className name of the class or module to use as the file name.
 */
private void saveExtractedModelsAsBinaryFile(value val, str className) {
    try {
        writeBinaryValueFile(|cwd:///| + MODELS_FOLDER + "<className>.bin", val);
        println("Successfully wrote <className>.bin");
    } catch IO(msg) : {
        println("[ERROR] Error writing <className>.bin: <msg> ");
    }
}

/**
 * Loads file paths listed in a specified text file.
 * 
 * @param filePath the location of the text file containing paths.
 * @return a list of file locations.
 */
public list[loc] loadFilePathsFromFile(loc filePath) {
    list[str] fileLines = readFileLines(filePath);
    return [ |file:///| + line | str line <- fileLines ];
}

/**
 * Loads all extracted models from disk and returns them as a list of ClassEntity instances.
 * 
 * @return a list of ClassEntity objects loaded from binary files in the models folder.
 */
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

/**
 * Reads a ModelContainer from a binary file.
 * 
 * @param file the location of the binary file to read.
 * @return the loaded ModelContainer.
 */
private ModelContainer loadExtractedModelsFromBinaryFile(loc file) {
    ModelContainer loadedModelContainer = readBinaryValueFile(#ModelContainer, file);

    return loadedModelContainer;
}