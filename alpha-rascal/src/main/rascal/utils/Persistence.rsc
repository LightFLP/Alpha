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

public void saveExtractedModelsToDisk(ModelContainer extractedModels, str className, bool saveAsJSon) {
    if(saveAsJSon) {
        saveExtractedM3ModelsAsJSON(extractedModels, className);
    }else{
        saveExtractedModelsAsBinaryFile(extractedModels, className);
    }
}

public void saveExtractedM3ModelsAsJSON(ModelContainer extractedModels, str className) {
    try {
        writeJSON(MODELS_LOC + "<className>.json", extractedModels[0]);
        println("Successfully wrote <className>.json");
    } catch IO(msg) : {
        println("Error writing <className>.json: <msg> ");
    }
}

public void saveComposedExtractedM3ModelsAsJSON(M3 composedM3Models, str appName) {
    try {
        writeJSON(MODELS_COMPOSED_LOC + "<appName>.json", composedM3Models);
        println("Successfully wrote <appName>.json");
    } catch IO(msg) : {
        println("Error writing <appName>.json: <msg> ");
    }
}

// Function to save a ModelContainer to a file.
private void saveExtractedModelsAsBinaryFile(value val, str className) {
    try {
        writeBinaryValueFile(MODELS_LOC + "<className>.bin", val);
        println("Successfully wrote <className>.bin");
    } catch IO(msg) : {
        println("Error writing <className>.bin: <msg> ");
    }
}

public list[ClassEntity] loadExtractedModelsFromDisk() {
    println("Loading extracted models from disk");

    set[loc] pathsOfModels = files(MODELS_LOC);

    println("Found <Set::size(pathsOfModels)> extracted models from disk");

    list[ClassEntity] listOfClassEntities = [];

    for(loc modelsPath <- pathsOfModels) {
        str className = getClassNameFromFilePath(modelsPath);
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