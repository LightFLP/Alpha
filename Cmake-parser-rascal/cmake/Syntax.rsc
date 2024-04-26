module lang::cmake::Syntax

layout Layout = WhitespaceAndComment* !>> [\ \t\n\r#];
lexical WhitespaceAndComment = [\ \t\n\r] | @category="Comment" "#" ![\n]* $;

start syntax Build = build: Statement* statements;
syntax Statement
        = \set: SetStat sets
        | conditional: Conditional condi
        | message: MsgStat msgs
        | project: ProjStat projs
        | addSetting: AddSetting adds
        | includeDir: IncludeDirectory dirs
        | srcGroup: SourceGroup sg
        | createGroup: CreateSrcGroup cg
        | nonArgFun: NonArgFun naf
        | confStat: Configure conf
        | option: Option opt
        | findComponent: FindComponent fc
        | file: File fileOperation
        | targetProperty: TargetProperty tp
        | setProperty: SetProperty sp
        | filenameComponent: FilenameComponent fnc
        | stringOperation: String strOperation
        | requirement: Requirement req
        | removeSetting: RemoveSetting rs
        | qt5: Qt5 qt
        | copyRun: CopyToRun ctr
        | loop: Loop lo
        | \list: ListStat lists
        | targetCompile: TargetCompile tc
        | dependency: Dependency dep
        | macroDef: MacroDefStat md
        | execProc: ExecuteProcess ep
        ;
syntax SetStat 
        = setList: "set" "(" "$" "{" Id targetMacro "}" TT targetType Source+ source? ")"
        | setCompileFlages: "set" "(" "$" "{" Id targetMacro "}" "_COMPILE_FLAGS" Source+ compileFlags ")"
        | setMapping: "set" "(" Id targetMacro Source* source ")" 
        | setMappingSlashI: "set" "(" "_out_inc_dirs_arg" "${_out_inc_dirs_arg} /I"? Source* source ")"
        | setMultiMacMapping: "set" "(" Id targetMacro Source sourcePre (";" Source sourcePost)+ ")"
        | setCache: "set" "(" Id targetMacro "\""? Id val "\""? "CACHE" FORMAT format Word* info "FORCE" ")"
        | setMacroCache: "set" "(" Id targetMacro "\"" "$" "{" Id val "}" Id suffix "\"" "CACHE" FORMAT format Word* info "FORCE" ")"
        | setString: "set" "(" "\"" Setting+ setInfo "\"" ")"
        ;
syntax Source 
        = sourceList: "\""? "$"? "{"? Id sourceFile "}"? "\""?
        | sourceListDollar: "$" "{" "$" "{" Id sourceFile "}" Id path "}"
        | sourceListSemi: Id sourceFile  ";"
        ;
syntax MsgStat = msgStat: "message" "(" Label label MsgInfo info ")";
syntax MsgInfo 
        = msgInfo: Id variableMacro "=" "$" Id? preMacro "{" Id targetMacro "}"
        | msgString: LongString+ words
        ;
syntax Conditional = conditional: IfStat ifs Statement* statements ElseStat* els "endif" "(" Condition? cond ")"; 
syntax IfStat = ifStat: "if" "(" Condition cond ")";
syntax ElseStat
        = \else : "else" "(" Condition? elseCond ")" Statement* statements
        | elseif: "elseif" "(" Condition elseIfCond")" Statement* statements
        ;
syntax Condition       
        = condition: Id id
        | conditionByWord: Word Word+
        | conditionDollar: Id id "${" Id parameter "}"
        | conditionDep: Id target "${" Id targetName "}" Id link "${" Id buildColor "}"
        ;
syntax ProjStat = projStat: ("project" | "Project" ) "(" Id projectName ")";
syntax AddSetting 
        = addSubdir: "add_subdirectory" "(" "$"? "{"? Id macroName "}"? Id? subPath BinaryDir? bin ")"
        | addDef: "add_definitions" "(" "/Yu"? "\""? "$"? "{"? Id def "}"? Id* defs "\""? ")"
        | addDefList: "add_definitions" "(" "-D_VSB_CONFIG_FILE=" "\"" Setting param "\"" Setting+ params ")"
        | addCompileDef: "add_compile_definitions" "(" Id macro ")"
        | addCompileOpt: "add_compile_options" "(" "\"" Id opt "\"" ")"
        | addDeppendency: "add_dependencies" "(" "${" Id targetName "}" Id link "${" Id buildColor "}" Dep+ dep ")"
        | addCustomCommand: "add_custom_command" "(" LongMsg+ parameters ")"
        | addCustomTarget: "add_custom_target" "(" LongMsg+ parameters ")"
        ;
syntax Dep 
        = dep: Id dependency
        | depDollar: Id prefix "${" Id macro "}"
        ;
syntax BinaryDir = binaryDir: "$" "{" Id macroName "}" Id? subPath;
syntax IncludeDirectory 
        = include: "include" "(" "${"? Id sourceFile "}"? Id? sourcePath ")" 
        | includeDir: "include_directories" "(" "SYSTEM"? Source+ source ")"
        ;
syntax SourceGroup 
        = groupRegex: "source_group(" Word+ groupNameRegex "REGULAR_EXPRESSION" H header1 "|" H header2 "|" H? header3 ")"
        | groupFiles: "source_group(" "\""? Id+ groupName "\""? "FILES" Source+ files ")"
        | groupNaive: "source_group(" "\"" Id+ groupName "\"" Source+ files ")"
        | groupTree: "source_group(TREE" "\"" "${" Id rootMacro "}" Id? sourcePath ("\"" "PREFIX" "\"" Id prefix)? "\"" "FILES" "${" Id macroName "}" ")"
        ;
syntax CreateSrcGroup = createSourceGroup: "createSourceGroupsBasedOnFolderStructure" "(" "\"" Source fileList "\"" Source projectFolder ")";
syntax Configure 
        = configureLibrary: "configureLibrary" "(" "$" "{" Id targetMacro "}" Id+ buildTarget ")"
        | configureTestLibrary: "configureTestLibrary" "(" "$" "{" Id targetMacro "}" Id+ buildTargetList ")"
        | configureTestExecutable: "configureTestExecutable" "(" "$" "{" Id targetMacro "}" Id buildTestExeTarget Id* obj ")"
        | configureIntegrationTestExecutable: "configureIntegrationTestExecutable" "(" "$" "{" Id targetMacro "}" Id buildIntTestExeTarget Id* buildTarget ")"
        | configureModuleTestExecutable: "configureModuleTestExecutable" "(" "$" "{" Id targetMacro "}" Id buildModTestExeTarget Id* obj ")"
        | configureClassTestExecutable: "configureClassTestExecutable" "(" "$" "{" Id targetMacro "}" Id buildClassTestExeTarget Id* obj ")"
        | configureExecutable: "configureExecutable" "(" "$" "{" Id targetMacro "}" Id buildExeTarget Id* obj ")"
        | configureGuiApp: "configureGuiApp" "(" "$" "{" Id targetMacro "}" Id+ buildGuiTarget ")"
        | configureDLL: "configureDLL" "(" "$" "{" Id dllName "}" Source embOpt ")"
        | configureProject: "configureProject" "(" Id name ")"
        | configureQtApp: "configureQtApp" "(" "$" "{" Id targetMacro "}" Id+ qtTarget ")"
        ;
syntax Option = option: "option" "(" Id targetMacro Word+ words")" ;
syntax FindComponent 
        = findPackage: "find_package" "(" Id targetMacro Id kw ")"
        | findFile: "find_file(" Word+ fileParameters ")"
        | findLib: "find_library(" LongString+ libParameters ")"
        ;
syntax File = file: "file" "(" Id command LongString+ operations ")";
syntax TargetProperty = targetProperty: "get_target_property" "(" Id var Word target Id property")"; // Note: this function may set some new macro variables
syntax SetProperty 
        = setProperty: "set_property" "(" Id command LongString* words "PROPERTY" Id propertyName LongString+ val  ")"
        | setSourceFilesProperty: "set_source_files_properties" "(" Source+ source "PROPERTIES" Word ("/"? LongString)+")"
        | setTargetPropertyNative: "set_target_properties" "(" Source+ targetName  "PROPERTIES" Property+ property ")"
        | setTargetPropertyCustom: "setTargetProperty" "(" "$" "{" Id targetMacro "}" Source+ targetProperty ")"
        ;
syntax Property = property: Id property LongString val;
syntax FilenameComponent 
        = filenameComponent: ("get_filename_component" | "GET_FILENAME_COMPONENT") "(" Id var LongString filename Id mode ")"; // Note: give a filename to a variable
syntax String = string: "string" "(" Id command LongString+ operations  ")"; // Note: this function may change the instance the macro variable refers to
syntax Requirement = requirement: "cmake_minimum_required" "(" "VERSION" Num id ")";
syntax RemoveSetting = removeDef: "remove_definitions" "(" Id def ")";
syntax Qt5 
        = qt5Cpp: "qt5_wrap_cpp" "(" Source+ target ")"
        | qt5UI: "qt5_wrap_ui" "(" Id file Source+ target ")"
        | qt5AddResource: "qt5_add_resources" "(" Id file Source+ target ")"
        ;
syntax CopyToRun = copyToRunDir: "copyToRunDir" "(" "${" Id targetName "}" "OBJ_TN" "${" Id runDir "}" ")";
syntax Loop = loop: "FOREACH" "(" Condition cond ")" Statement* statements "ENDFOREACH" "(" ")"; 
syntax TargetCompile = targetCompileOpt: "target_compile_options" "(" Source+ target Modifier modifier Source opt ")";
syntax ListStat = listStat: "list" "(" Id cmd Source+ target ")";
syntax Dependency
        = defineDependencies: "DefineDependencies" "(" "$" "{" Id depName "}" ")"
        | macroFileDependencies: "MACRO_ADD_FILE_DEPENDENCIES" "(" Source+ deps ")"
        ;
syntax MacroDefStat = macroDefStat: "macro" "(" Id macroName Id+ macroParameters")" Statement+ statements "endmacro" "(" Id macroNameEnd ")";
syntax ExecuteProcess = executeProcess: "execute_process" "(" LongString+ parameters ")";

syntax Label = "STATUS" | "FATAL_ERROR";
syntax Modifier = "INTERFACE" | "PUBLIC" | "PRIVATE";
syntax BOOL = "ON" | "OFF";
syntax FORMAT = "STRING" | "FILEPATH";
syntax NonArgFun = "writeExecTestHeader()" | "writeExecTestFooter()";

lexical Id = ([a-zA-Z0-9/.\-_\<][a-zA-Z0-9_/.\-=:+\\?\<\>]* !>> [a-zA-Z0-9_/.\-=:+\\?\>]) \ Reserved;
lexical TT = ([_][A-Za-z_]* !>> [A-Za-z_]) \ Reserved;
lexical H = ([.][*\\.hp]*) \ Reserved;
lexical Word = [a-zA-Z\"(_\-&][a-zA-Z0-9\":/.(){}$_\\=,]* !>> [a-zA-Z0-9\":/.{}_\r\n$\\=,] \ Reserved;
lexical LongString = [a-zA-Z\"$._\-0-9][a-zA-Z0-9\"${}_\-/.\\=*:,]* !>> [a-zA-Z0-9\"$}_\-/.\\=*:,] \ Reserved;
lexical LongMsg = [a-zA-Z\"$._\-=&/][a-zA-Z0-9\"${}()_\-/.\\=*:,&/]* !>> [a-zA-Z0-9\"$}_\-/.\\=*:,&/] \ Reserved;
lexical Num = [0-9][0-9.]* !>> [0-9];
lexical Setting = [a-zA-Z$\-][a-zA-Z0-9_{}\-=]* !>> [a-zA-Z0-9$}_\-=] \ Reserved;

keyword Reserved = "source_group" | "set" | "SYSTEM" | "if" | "else" | "elseif" | "$" | "{" | "}" | 
		"_COMPILE_FLAGS" | "configureLibrary" | "configureTestExecutable" | "FILES" | "REGULAR_EXPRESSION" |
                 "INTERFACE" | "PUBLIC" | "PRIVATE" | "PROPERTIES" | "TREE" | "CACHE" | "STRING" | "FORCE" | "FILEPATH" | "_out_inc_dirs_arg"; 