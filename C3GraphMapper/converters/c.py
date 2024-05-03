from copy import deepcopy
import re
import os
import json

class C:
    primitives = ["int", "float", "void", "char", "string", "boolean"]
    viz = {"elements": {"nodes": [], "edges": []}}
    parsed = None
    path = None

    def __init__(self, path, parsed, issues=None) -> None:
        self.path = path
        self.parsed = parsed
        self.issues = issues

    def add_edges(self, kind, content):
        match kind:
            case "hasScript":
                edge_id = hash(content[0])
                self.viz["elements"]["edges"].append(
                    {
                        "data": {
                            "id": edge_id,
                            "source": content[1]["class"],
                            "properties": {"weight": 1},
                            "target": content[0],
                            "labels": [kind],
                        }
                    }
                )
                try:
                    edge_id = (
                        hash(content[1]["class"])
                        + hash(content[0])
                        + hash(content[1]["location"]["file"])
                    )
                    self.viz["elements"]["edges"].append(
                        {
                            "data": {
                                "id": edge_id,
                                "source": content[1]["location"]["file"],
                                "properties": {"weight": 1},
                                "target": content[0],
                                "labels": ["contains"],
                            }
                        }
                    )
                except:
                    source = next(
                        item
                        for item in self.viz["elements"]["edges"]
                        if item["data"]["target"] == content[1]["class"]
                        and "contains" in item["data"]["labels"]
                    )
                    edge_id = (
                        hash(content[1]["class"])
                        + hash(content[0])
                        + hash(source["data"]["source"])
                    )

                    self.viz["elements"]["edges"].append(
                        {
                            "data": {
                                "id": edge_id,
                                "source": source["data"]["source"],
                                "properties": {"weight": 1},
                                "target": content[0],
                                "labels": ["contains"],
                            }
                        }
                    )
            case "hasParameter":
                for parameter in content[1]["parameters"]:
                    if parameter is not None and parameter != "":
                        edge_id = hash(parameter["name"]) + hash(content[0])
                        self.viz["elements"]["edges"].append(
                            {
                                "data": {
                                    "id": edge_id,
                                    "source": content[0],
                                    "properties": {"weight": 1},
                                    "target": content[0] + "." + parameter["name"],
                                    "labels": [kind],
                                }
                            }
                        )
                        edge_id = (
                            hash(parameter["name"])
                            + hash(content[0])
                            + hash(content[1]["location"]["file"])
                        )
                        self.viz["elements"]["edges"].append(
                            {
                                "data": {
                                    "id": edge_id,
                                    "source": content[1]["location"]["file"],
                                    "properties": {"weight": 1},
                                    "target": content[0] + "." + parameter["name"],
                                    "labels": ["contains"],
                                }
                            }
                        )
            case "returnType":
                edge_id = hash(content[0]) + hash(content[1]["returnType"])
                if content[1]["returnType"] is not None:
                    self.viz["elements"]["edges"].append(
                        {
                            "data": {
                                "id": edge_id,
                                "source": content[0],
                                "properties": {"weight": 1},
                                "target": content[1]["returnType"],
                                "labels": [kind],
                            }
                        }
                    )
            case "specializes":
                edge_id = hash(content[0]) + hash(content[1]["extends"])
                self.viz["elements"]["edges"].append(
                    {
                        "data": {
                            "id": edge_id,
                            "source": content[0],
                            "properties": {"weight": 1},
                            "target": content[1]["extends"],
                            "labels": [kind],
                        }
                    }
                )
            case "hasVariable":
                for variable in content[1]["variables"]:
                    if variable is not None and variable != "":
                        edge_id = hash(variable["name"]) + hash(content[0])
                        self.viz["elements"]["edges"].append(
                            {
                                "data": {
                                    "id": edge_id,
                                    "source": content[0],
                                    "properties": {"weight": 1},
                                    "target": content[0] + "." + variable["name"],
                                    "labels": [kind],
                                }
                            }
                        )
                        edge_id = (
                            hash(variable["name"])
                            + hash(content[0])
                            + hash(content[1]["location"]["file"])
                        )
                        self.viz["elements"]["edges"].append(
                            {
                                "data": {
                                    "id": edge_id,
                                    "source": content[1]["location"]["file"],
                                    "properties": {"weight": 1},
                                    "target": content[0] + "." + variable["name"],
                                    "labels": ["contains"],
                                }
                            }
                        )
            case "invokes":
                edge_id = hash(content["target"]) + hash(content["source"])
                self.viz["elements"]["edges"].append(
                    {
                        "data": {
                            "id": edge_id,
                            "source": content["source"],
                            "properties": {"weight": 1},
                            "target": content["target"],
                            "labels": [kind],
                        }
                    }
                )
            case "contains":
                if content[1]["location"].get("file") is None:
                    pass
                else:
                    edge_id = hash(content[0]) + hash(content[1]["location"]["file"])
                    self.viz["elements"]["edges"].append(
                        {
                            "data": {
                                "id": edge_id,
                                "source": content[1]["location"]["file"],
                                "properties": {"weight": 1},
                                "target": content[0],
                                "labels": [kind],
                            }
                        }
                    )
            case "type":
                content = list(zip(content.keys(), content.values()))[0]
                id = hash(content[0]) - hash(content[1]["name"])
                if len(content[1]["type"]) != 0:

                    self.viz["elements"]["edges"].append(
                        {
                            "data": {
                                "id": id,
                                "source": content[0] + "." + content[1]["name"],
                                "properties": {"weight": 1},
                                "target": content[1]["type"],
                                "labels": [kind],
                            }
                        }
                    )

    def add_nodes(self, kind, content):
        match kind:
            case "file":
                self.viz["elements"]["nodes"].append(
                    {
                        "data": {
                            "id": content,
                            "properties": {"simpleName": content, "kind": kind},
                            "labels": ["Container"],
                        }
                    }
                )
            case "function":
                vulnerabilities = []
                if self.issues is not None:
                    for issue in self.issues:
                        if issue["target"]["script"] == content[0]:
                            vulnerabilities.append(issue)
                self.viz["elements"]["nodes"].append(
                    {
                        "data": {
                            "id": content[0],
                            "properties": {
                                "simpleName": content[1]["functionName"],
                                "kind": kind,
                                "vulnerabilities": vulnerabilities,
                                "location": content[1]["location"],
                            },
                            "labels": [
                                "Operation",
                                "vulnerable" if len(vulnerabilities) > 0 else "",
                            ],
                        }
                    }
                )
            case "parameter":
                for parameter in content[1]["parameters"]:
                    if parameter is not None and parameter != "":
                        self.viz["elements"]["nodes"].append(
                            {
                                "data": {
                                    "id": content[0] + "." + parameter["name"],
                                    "properties": {
                                        "simpleName": parameter["name"],
                                        "kind": kind,
                                    },
                                    "labels": ["Variable"],
                                }
                            }
                        )
                        if "type" in parameter.keys() and parameter["type"] is not None:
                            self.add_edges("type", {content[0]: parameter})
            case "method":
                vulnerabilities = []
                if self.issues is not None:
                    for issue in self.issues:
                        if issue["target"]["script"] == content[0]:
                            vulnerabilities.append(issue)
                self.viz["elements"]["nodes"].append(
                    {
                        "data": {
                            "id": content[0],
                            "properties": {
                                "simpleName": content[1]["methodName"],
                                "kind": kind,
                                "vulnerabilities": vulnerabilities,
                            },
                            "labels": [
                                "Operation",
                                "vulnerable" if len(vulnerabilities) > 0 else "",
                            ],
                        }
                    }
                )
            case "class":
                vulnerabilities = []
                if self.issues is not None:
                    for issue in self.issues:
                        if issue["target"]["script"] == content[0]:
                            vulnerabilities.append(issue)
                self.viz["elements"]["nodes"].append(
                    {
                        "data": {
                            "id": content[0],
                            "properties": {
                                "simpleName": content[1]["className"],
                                "kind": kind,
                                "vulnerabilities": vulnerabilities,
                            },
                            "labels": [
                                "Structure",
                                "vulnerable" if len(vulnerabilities) > 0 else "",
                            ],
                        }
                    }
                )
            case "Primitive":
                self.viz["elements"]["nodes"].append(
                    {
                        "data": {
                            "id": content,
                            "properties": {"simpleName": content, "kind": kind},
                            "labels": [kind],
                        }
                    }
                )
            case "variable":
                for variable in content[1]["variables"]:
                    if variable is not None and variable != "":
                        self.viz["elements"]["nodes"].append(
                            {
                                "data": {
                                    "id": content[0] + "." + variable["name"],
                                    "properties": {
                                        "simpleName": variable["name"],
                                        "kind": kind,
                                    },
                                    "labels": ["Variable"],
                                }
                            }
                        )
                        if "type" in variable.keys() and variable["type"] is not None:
                            self.add_edges("type", {content[0]: variable})

    def get_files(self):
        data = self.parsed["provides"]
        files = []
        for f in data:
            files.append(f[0])
        files = list(dict.fromkeys(files))
        for f in files:
            files[files.index(f)] = re.sub("\/.+\/", "", f)
        return files

    def get_function_location(self, function):
        data = self.parsed["functionDefinitions"]
        location = {}
        for element in data:
            if re.match("c\+function:", element[0]) and function in element[0]:
                location["file"], location["position"] = re.split("\(", element[1])
                location["file"] = re.sub("\|file:.+/", "", location["file"])[:-1]
                location["position"] = "(" + location["position"]
                break
        return location

    def get_method_location(self, className, method):
        data = self.parsed["functionDefinitions"]
        location = {}
        for element in data:
            if re.match("cpp\+method:\/+{}\/{}".format(className, method), element[0]):
                location["file"], location["position"] = re.split("\(", element[1])
                location["file"] = re.sub("\|file:.+/", "", location["file"])[:-1]
                location["position"] = "(" + location["position"]
                break
        return location

    def get_functions(self):
        functions = {}
        data = self.parsed["declaredType"]
        for element in data:
            if re.match("c\+function:", element[0]):
                parameters = []
                function = dict()
                function["functionName"] = re.split(
                    "\(", re.sub("c\+function:\/+", "", element[0])
                )[0]

                function["location"] = self.get_function_location(
                    function["functionName"]
                )
                returnField = self.get_type_field(element[1]["returnType"])
                function["returnType"] = self.get_type(
                    element[1]["returnType"], returnField
                )

                """ if element[1]["parameterTypes"]:
                    parameters = self.get_parameters(
                        function["functionName"], function["location"]["file"]
                    )
                    i = 0
                    for parameter in element[1]["parameterTypes"]:

                        print(i,"\n \n \n")
                        parameters[i]["type"] = self.get_parameter_type(
                            parameter, self.get_type_field(parameter)
                        )
                        i += 1
                function["parameters"] = parameters """
                function["variables"] = self.get_variables(element[0])
                functions[function["functionName"]] = function
        return functions

    def get_variables(self, operator):
        variables = []
        data = self.parsed["declaredType"]
        operator_name = "c+variable:" + re.split("c\+.+:", operator)[1]
        for element in data:
            if re.match("c\+variable:", element[0]) and operator_name in element[0]:
                variable = {}
                variable["name"] = re.sub("c\+variable:.+/", "", element[0])
                if (
                    self.get_type(element[1], self.get_type_field(element[1]))
                    is not None
                ):
                    variable["type"] = self.get_type(
                        element[1], self.get_type_field(element[1])
                    )
                variables.append(variable)
        return variables

    def get_methods(self):
        data = self.parsed["declaredType"]
        methods = {}
        for element in data:
            parameters = []
            if re.match("cpp\+method", element[0]):
                method = dict()
                method["class"] = re.split(
                    "\/", re.sub("cpp\+method:\/+", "", element[0])
                )[0]
                method["methodName"] = re.split(
                    "\(", re.sub("cpp\+method:\/+.+/", "", element[0])
                )[0]

                method["location"] = self.get_method_location(
                    method["class"], method["methodName"]
                )

                method["returnType"] = self.get_type(
                    element[1]["returnType"],
                    self.get_type_field(element[1]["returnType"]),
                )
                if element[1]["parameterTypes"]:
                    parameters = self.get_parameters(
                        method["methodName"],
                        method["location"]["file"],
                        method["class"],
                    )
                    i = 0
                    for parameter in element[1]["parameterTypes"]:
                        parameters[i]["type"] = self.get_parameter_type(
                            parameter, self.get_type_field(parameter)
                        )
                        i += 1
                method["parameters"] = parameters
                method["variables"] = self.get_variables(element[0])
                id = method["class"] + "." + method["methodName"]
                methods[id] = method
        return methods

    def get_type_field(self, element):
        try:
            if "baseType" in element.keys():
                return "baseType"
            if "decl" in element.keys():
                return "decl"
            if "type" in element.keys():
                return "type"
            if "msg" in element.keys():
                return "msg"
            if "templateArguments" in element.keys():
                return None
        except:
            return None

    def get_type_deprecated(self, element, field1, field2):
        if field2 == "decl":
            return re.sub("cpp\+class:\/+", "", element[1][field1][field2])
        if field2 == "type":
            if "decl" in element[1][field1][field2].keys():
                if (
                    element[1][field1][field2]["decl"]
                    == "cpp+classTemplate:///std/__cxx11/basic_string"
                ):
                    return "string"
                else:
                    return re.sub(
                        "cpp\+class:\/+",
                        "",
                        element[1][field1][field2]["decl"],
                    )
            if "type" in element[1][field1][field2].keys():
                if "decl" in element[1][field1][field2]["type"].keys():
                    if "type" in element[1][field1][field2]["type"].keys():
                        if (
                            element[1][field1][field2]["type"]["type"]["decl"]
                            == "cpp+classTemplate:///std/__cxx11/basic_string"
                        ):
                            return "string"
                        return re.sub(
                            "cpp\+class:\/+",
                            "",
                            element[1][field1][field2]["type"]["type"]["decl"],
                        )
                    if (
                        element[1][field1][field2]["type"]["decl"]
                        == "cpp+classTemplate:///std/__cxx11/basic_string"
                    ):
                        return "string"
                    return re.sub(
                        "cpp\+class:\/+", "", element[1][field1][field2]["type"]["decl"]
                    )
        if field2 == "baseType":
            return element[1][field1][field2]

    def get_type(self, element, field):
        if field is None:
            return None
        if self.get_type_field(element[field]) is not None:
            return self.get_type(element[field], self.get_type_field(element[field]))
        else:
            if field == "baseType":
                return element[field]
            if field == "decl":
                return None
            if field == "msg":
                return None

    def get_parameter_type(self, element, field):
        if field == "decl":
            return None
        if field == "type":
            if "decl" in element[field].keys():
                if (
                    element[field]["decl"]
                    == "cpp+classTemplate:///std/__cxx11/basic_string"
                ):
                    return "string"
                else:
                    return None
            if "baseType" in element[field].keys():
                return element[field]["baseType"]
            if "modifiers" in element[field].keys():
                pass
        if field == "baseType":
            return element[field]

    def get_parameters(self, function, location, class_name=None):
        data = self.parsed["declarations"]
        parameters = []
        if location is None:
            return parameters
        if class_name is not None:
            find = "" + class_name + "/" + function
        else:
            find = function
        for element in data:

            if (
                re.match("cpp\+parameter", element[0])
                and location in element[1]
                and re.match("\|file:\/+.+.\|", element[1])
            ):
                parameter = {}
                parameter["name"] = re.sub("cpp\+parameter:\/+", "", element[0])
                parameter["location"] = int(
                    re.split(",", re.sub("\|file:\/+.+\|\(", "", element[1]))[0]
                )

                parameters.append(parameter)
        parameters = sorted(parameters, key=lambda d: d["location"])

        return parameters

        data = self.parsed["functionDefinitions"]
        location = {}
        for element in data:
            if re.match("cpp\+constructor:\/+\/" + c, element[0]) and c in element[0]:
                location["file"], location["position"] = re.split("\(", element[1])
                location["file"] = re.sub("\|file:.+/", "", location["file"])[:-1]
                location["position"] = "(" + location["position"]
                break
        return location

    def get_invokes(self, operations):
        data = self.parsed["callGraph"]
        invokes = []
        for operation in operations.items():
            for element in data:
                if re.match(".+\.", operation[0]):
                    source = operation[0].replace(".", "/")
                else:
                    source = operation[0]
                if source in element[0]:
                    invoke = {}
                    invoke["source"] = operation[0]
                    try:
                        target = re.sub("c\+function:\/+.+\/", "", element[1])
                        if re.match("c\+", target):
                            target = re.sub("cpp\+method:\/+", "", element[1])
                            target = target.replace("/", ".")
                        target = re.split("\(", target)[0]

                        if target in operations.keys():
                            invoke["target"] = target
                            invokes.append(invoke)
                    except:
                        pass
                else:
                    pass
        return invokes

    def export(self):
        for file in self.get_files():
            self.add_nodes("file", file)
        for primitve in self.primitives:
            self.add_nodes("Primitive", primitve)
        functions = self.get_functions()
        for func in functions.items():
            self.add_nodes("function", func)
            """ if func[1]["parameters"]:
                self.add_nodes("parameter", func)
                self.add_edges("hasParameter", func) """
            if func[1]["variables"]:
                self.add_nodes("variable", func)
                self.add_edges("hasVariable", func)
            self.add_edges("returnType", func)
            self.add_edges("contains", func)

        operations = deepcopy(functions)
        for invoke in self.get_invokes(operations):
            self.add_edges("invokes", invoke)
        with open(os.path.join(self.path, "converted.json"), "w") as f:
            f.write(json.dumps(self.viz))
