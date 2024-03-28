module utils::CMakeUtils

import Prelude;
import Location;
import util::FileSystem;
import lang::json::IO;
import util::Math;

// get all CMakeLists.txt, CMakelists.txt, *.cmake files under the target directories
list[loc] getCmakeList(list[loc] targets){
    return [*searchCmakeFile(trg) | trg <- targets];
}

// recursive searching for getCmakeList()
list[loc] searchCmakeFile(loc root){
    list[loc] cmakeFileList = [];
    if(!isFile(root)){
        for(f <- root.ls){
            cmakeFileList += searchCmakeFile(f);
        }
    }else{
        if(root.file == "CMakeLists.txt" || root.file == "CMakelists.txt" || root.extension == "cmake"){
            return [root];
        }else{
            return [];
        }
    }
    return cmakeFileList;
}

// get all headers / source files from the posxxx modules
list[loc] getTargetList(list[loc] targetsOriginal, bool isSource){
    if(isSource){ 
        return [*toList(find(x, bool (loc l) { return l.extension == "cpp" || l.extension == "c"; })) | x <- targetsOriginal];
    }else{ 
        return [*toList(find(x, bool (loc l) { return l.extension == "hpp" || l.extension == "h"; })) | x <- targetsOriginal];
    }
}

map[loc, set[loc]] addSetToMap(map[loc, set[loc]] targetMap, loc key, set[loc] val){
    if(key in targetMap){
        targetMap[key] += val;
    }else{
        targetMap += (key : val);
    }
    return targetMap;
}

set[str] toStrSet(list[loc] locList){
    return {x.uri | x <- locList};
}

set[loc] toSingleSet(set[set[loc]] targetSet){
    return {*x | x <- targetSet};
}

set[loc] convertPathsToLower(set[loc] pathSet){
    return {convertSinglePathToLower(x) | x <- pathSet};
}

loc convertSinglePathToLower(loc path){
    return toLocation(toLowerCase(path.uri));
}

bool isChildPath(list[loc] parentPaths, loc target){
    target = target.top;
    target = toLocation(toLowerCase(replaceAll(target.uri, "%5C", "/")));
    while(target.parent ?){
        if(target.parent in parentPaths){
            return true;
        }
        target = target.parent;
    }
    return false;
}

bool isParentPath(list[loc] childPaths, loc target){
    for(x <- childPaths){
        if(startsWith(toLowerCase(x.uri), toLowerCase(target.uri))){
            return true;
        }
    }
    return false;
}

str findCategory(rel[loc, str] pathToCategory, loc target){
    target = toLocation(toLowerCase(replaceAll(target.uri, "%5C", "/")));
    if(target in pathToCategory<0>){
        return getFirstFrom(pathToCategory[target]);
    }
    while(target.parent ?){
        if(target.parent in pathToCategory<0>){
            return getFirstFrom(pathToCategory[target.parent]);
        }
        target = target.parent;
    }
    return "";
}

str findLayerName(rel[list[loc], str] pathsToLayer, loc target){
    str res = "";
    for(paths <- pathsToLayer<0>){
        if(isChildPath(paths, target)){
            res = getFirstFrom(pathsToLayer[paths]);
            break;
        }
    }
    return res;
}

data Path 
    = path(map[str, map[str, list[str]]] paths)
    | include(map[loc, list[loc]] include)
    ;
void writeIncludePathToJson(rel[loc, list[loc]] inc, rel[loc, list[loc]] lib, loc target){
    map[loc, list[loc]] pathMap = ();
    for(source <- inc<0>){
        pathMap += (source : getFirstFrom(inc[source]) + getFirstFrom(lib[source]));
    }
    writeJSON(target, include(pathMap) , indent=4, unpackedLocations=false);    // to read: readJSON(#map[str, map[loc, list[loc]]], target)
    // writeJSON(target, include(pathMap) , indent=4, unpackedLocations=true);
}

void writePathToJson(map[str, map[str, list[str]]] pathList, loc target){
    writeJSON(target, path(pathList) , indent=4, unpackedLocations=false);
}

// for large file: split and save to disk
void splitAndWrite(rel[loc, loc] target, int split, str name, loc prefix=|file:///C:/workspace/rascal/erosion-checker/output|){
    int i = 0;
    int k = 0;
    int threshold = size(target) / split + 1;
    rel[loc, loc] temp = {};
    while(k < 4){
        temp = {};
        i = 0;
        for(t <- target){
            if(i == threshold){
                break;
            }
            temp += t;
            i += 1;
        }
        writeBinaryValueFile(prefix + (name + toString(k)), temp);
        iprintln("finished <toString(k)>");
        k += 1;
        target -= temp;
    }
}