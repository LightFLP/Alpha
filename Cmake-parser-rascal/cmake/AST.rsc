module lang::cmake::AST

data Build = build(list[Statement] statements);
data Statement 
        = \set(SetStat sets)
        | conditional(Conditional condi)
        | message(MsgStat msgs)
        | project(ProjStat projs)
        | addSetting(AddSetting adds)
        | includeDir(IncludeDirectory dirs)
        | srcGroup(SourceGroup sg)
        | createGroup(CreateSrcGroup cg)
        | nonArgFun(str naf)
        | confStat(Configure conf)
        | option(Option opt)
        | findComponent(FindComponent fp)
        | file(File fileOperation)
        | targetProperty(TargetProperty tp)
        | setProperty(SetProperty sp)
        | filenameComponent(FilenameComponent fnc)
        | stringOperation(String strOperation)
        | requirement(Requirement req)
        | removeSetting(RemoveSetting rs)
        | qt5(Qt5 qt)
        | copyRun(CopyToRun ctr)
        | loop(Loop lo)
        | \list(ListStat lists)
        | targetCompile(TargetCompile tc)
        | dependency(Dependency dep)
        | macroDef(MacroDefStat md)
        | execProc(ExecuteProcess ep)
        ;
data SetStat 
        = setList(str targetMacro, str targetType, list[Source] source)
        | setCompileFlages(str targetMacro, list[Source] compileFlags)
        | setMapping(str targetMacro, list[Source] source)              // note: setMapping(str targetMacro, str path) --> get one untruncated line, e.g. "\"${PROJECT_SOURCE_DIR}/../../BuildPos\"",
        | setMappingSlashI(str opt, list[Source] source)
        | setMultiMacMapping(str targetMacro, Source sourcePre, list[Source] sourcePost)
        | setCache(str targetMacro, str cmtOpen, str val, str cmtClose, str format, str info)
        | setMacroCache(str targetMacro, str val, str suffix, str format, str info)
        | setString(str setInfo)
        ;
data Source 
        = sourceList(str cmtOpen, str dollar, str accOpen, str sourceFile, str accClosed, str cmtClosed)
        | sourceListDollar(str sourceFile, str path)
        | sourceListSemi(str sourceFile)
        ;
data MsgStat = msgStat(str label, MsgInfo info);
data MsgInfo 
        = msgInfo(str variableMacro, str preMacro, str targetMacro)
        | msgString(list[str] words)
        ;
data Conditional 
        = conditional(IfStat ifs, list[Statement] statements, list[ElseStat] els, list[Condition] cond);
data IfStat = ifStat(Condition cond);
data ElseStat
        = \else(list[Condition] elseCond, list[Statement] statements) 
        | elseif(Condition elseIfCond, list[Statement] statements);
data Condition 
        = condition(str targetMacro)
        | conditionByWord(str word, str wordList)
        | conditionDollar(str id, str parameter)
        | conditionDep(str target, str targetName, str link, str buildColor)
        ;
data ProjStat = projStat(str project, str projectName);
data AddSetting 
        = addSubdir(str dollar, str accOpen, str macroName, str accClosed, str subPath, list[BinaryDir] bin)
        | addDef(str yu, str cmtOpen, str dollar, str accOpen, str def, str accClose, list[str] defs, str cmtClose)
        | addDefList(str param, str params)
        | addCompileDef(str macro)
        | addCompileOpt(str opt)
        | addDeppendency(str targetName, str link, str buildColor, list[Dep] dep)
        | addCustomCommand(str parameters)
        | addCustomTarget(str parameters)
        ;
data Dep 
        = dep(str dependency) 
        | depDollar(str prefix, str macro)
        ;
data BinaryDir = binaryDir(str macroName, str subPath);
data IncludeDirectory 
        = include(str open, str sourceFile, str close, str sourcePath)
        | includeDir(str system, list[Source] dir);
data SourceGroup 
        = groupRegex(str groupNameRegex, str header1, str header2, str header3)
        | groupFiles(str cmtOpen, str groupName, list[Source] files, str cmtClose)
        | groupNaive(str groupName, list[Source] files)
        | groupTree(str rootMacro, str sourcePath, list[str] prefix, str macroName)
        ;
data CreateSrcGroup = createSourceGroup(Source fileList, Source projectFolder);
data Configure 
        = configureLibrary(str targetMacro, list[str] buildTarget)
        | configureTestLibrary(str targetMacro, list[str] buildTargetList)
        | configureTestExecutable(str targetMacro, str buildTestExeTarget, list[str] obj)
        | configureIntegrationTestExecutable(str targetMacro, str buildIntTestExeTarget, list[str] buildTarget)
        | configureModuleTestExecutable(str targetMacro, str buildModTestExeTarget, list[str] obj)
        | configureClassTestExecutable(str targetMacro, str buildClassTestExeTarget, list[str] obj)
        | configureExecutable(str targetMacro, str buildExeTarget, list[str] obj)
        | configureGuiApp(str targetMacro, list[str] buildGuiTarget)
        | configureProject(str name)
        | configureDLL(str dllName, Source embOpt)
        | configureQtApp(str targetMacro, list[str] qtTarget)
        ; 
data Option = option(str targetMacro, list[str] words);
data FindComponent 
        = findPackage(str targetMacro, str kw)
        | findFile(list[str] fileParameters)
        | findLib(list[str] libParameters)
        ;
data File = file(str command, str operations);
data TargetProperty = targetProperty(str var, str target, str property);
data SetProperty 
        = setProperty(str command, str words, str propertyName, str val)
        | setSourceFilesProperty(list[Source] source, str prop, list[str] propList)
        | setTargetPropertyNative(list[Source] targetName, list[Property] property)
        | setTargetPropertyCustom(str targetMacro, list[Source] targetProperty)
        ;
data Property = property(str property, str val);
data FilenameComponent = filenameComponent(str fun, str var, str filename, str mode);
data String = string(str command, str operations);
data Requirement = requirement(str id );
data RemoveSetting = removeDef(str def);
data Qt5 
        = qt5Cpp(list[Source] target)
        | qt5UI(str file, list[Source] target)
        | qt5AddResource(str file, list[Source] target)
        ;
data CopyToRun = copyToRunDir(str target, str dir);
data Loop = loop(Condition cond, list[Statement] statements);
data ListStat = listStat(str cmd, list[Source] target);
data TargetCompile = targetCompileOpt(list[Source] target, str modifier, Source opt);
data Dependency
        = defineDependencies(str depName)
        | macroFileDependencies(list[Source] deps)
        ;
data MacroDefStat = macroDefStat(str macroName, list[str] macroParameters, list[Statement] statements, str macroNameEnd);
data ExecuteProcess = executeProcess(str parameters);

anno loc Build@location;
anno loc Statement@location;
anno loc SetStat@location;
anno loc Source@location;
anno loc MsgStat@location;
anno loc MsgInfo@location;
anno loc Conditional@location;
anno loc IfStat@location;
anno loc ElseStat@location;
anno loc Condition@location;
anno loc ProjStat@location;
anno loc AddSetting@location;
anno loc Dep@location;
anno loc BinaryDir@location;
anno loc IncludeDirectory@location;
anno loc SourceGroup@location;
anno loc CreateSrcGroup@location;
anno loc Configure@location;
anno loc Option@location;
anno loc FindComponent@location;
anno loc File@location;
anno loc TargetProperty@location;
anno loc SetProperty@location;
anno loc FilenameComponent@location;
anno loc String@location;
anno loc Requirement@location;
anno loc RemoveSetting@location;
anno loc Qt5@location;
anno loc CopyToRun@location;
anno loc Loop@location;
anno loc ListStat@location;
anno loc TargetCompile@location;
anno loc Dependency@location;
anno loc MacroDefStat@location;
anno loc ExecuteProcess@location;
