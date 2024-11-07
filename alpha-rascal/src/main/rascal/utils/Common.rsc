module utils::Common

import String;

// Parse file location and return the name of the transaction unit or the module/project without the extension
public str getNameFromFilePath(loc filePath) {
    str pathAsString = filePath.path;
    int indexLastBackSlash = findLast(pathAsString, "\\");
    int indexLastSlash = findLast(pathAsString, "/");
    int indexExtensionStart = findLast(pathAsString, ".");
    int startOfName = (indexLastSlash > indexLastBackSlash) ? indexLastSlash : indexLastBackSlash;

    str fileName = substring(pathAsString, startOfName + 1, indexExtensionStart);
    
    return fileName;
}