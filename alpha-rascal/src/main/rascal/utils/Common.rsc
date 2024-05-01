module utils::Common

import String;

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