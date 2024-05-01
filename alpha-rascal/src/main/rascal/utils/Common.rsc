module utils::Common

import IO;
import String;

import utils::Constants;

// Read file paths from a text file
public list[loc] readFilePathsFromFile(loc filePath) {
    list[str] fileLines = readFileLines(filePath);
    return [ |file:///| + line | str line <- fileLines ];
}

// Read file paths from a text file
public void writeListToFile(str className, list[str] listToWrite) {
    writeFileLines(MODELS_LOC + "<className>-missing-includes.json", listToWrite);
}

// Parse file location and return the name of the class without the extension
public str getClassNameFromFilePath(loc filePath) {
    str pathAsString = filePath.path;
    int indexLastBackSlash = findLast(pathAsString, "\\");
    int indexLastSlash = findLast(pathAsString, "/");
    int indexExtensionStart = findLast(pathAsString, ".");
    int startOfClassName = (indexLastSlash > indexLastBackSlash) ? indexLastSlash : indexLastBackSlash;

    str fileName = substring(pathAsString, startOfClassName + 1, indexExtensionStart);
    
    return fileName;
}