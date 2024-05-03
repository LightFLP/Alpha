import json
from lpg_validator import find_node_discrpenecies
from converters import Cpp

app_name = "CoAxisLimitsOverride"
models_path = "C:\\Development\\TF\\Alpha\\alpha-rascal\\models"

path_of_composed_model = (
    f"{models_path}\\{app_name}.json"
)
path_of_vizualization = (
    f"{models_path}\\{app_name}.lpg.json"
)

def main():


    with open(path_of_composed_model, "r") as c3_json:
        parsed_json = json.load(c3_json)

        converter = Cpp
        cpp_converter = converter(
            models_path, 
            parsed_json, 
            None
        )

        cpp_converter.export(app_name)
        print(f"exported {path_of_vizualization}")


main()

result = find_node_discrpenecies(path_of_vizualization)
print(f"Missing IDs: {result}")
