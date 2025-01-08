module utils::PathMapper

import IO;
import List;
import String;
import Exception;

str rootMount = "/app/host";  // Root mount directory in the container

// Function to replace host paths with container paths
list[loc] mapPaths(list[str] hostPaths, str localDrive) {
    return [ 
        |file:///| + replaceFirst(path, localDrive, rootMount) 
        | path <- hostPaths 
    ];
}

// Main function
list[loc] processInputPaths(loc inputFile, str localDrive) {

    try {
        list[str] hostPaths = readFileLines(inputFile);
        list[loc] containerPaths = mapPaths(hostPaths, localDrive);
        return containerPaths;
    } catch IO(msg) : {
        println("Error reading file: <msg>");
    }

    return [];
}