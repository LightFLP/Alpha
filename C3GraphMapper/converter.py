import json
import re
import logging
from visualization_verifier import verify_integrity
from python_parsers import Cpp

path_of_composed_model = (
    "C:\\Development\\TF\\Alpha\\alpha-rascal\\models\\composed\\Velox.json"
)
path_of_cleaned_model = (
    "C:\\Development\\TF\\Alpha\\alpha-rascal\\models\\composed\\Velox_clean.json"
)
path_of_vizualization = (
    "C:\\Development\\TF\\Alpha\\alpha-rascal\\models\\composed\\Velox.viz.json"
)


def remove_rule(item):
    try:
        if re.match("problem", item) is None:
            return item
    except:
        return item
    return None


# Remove all problem statements from M3 models
def cleaner(path):
    # logging.info("Starting cleaning process")

    with open(path, "r") as dirty:
        parsed = json.load(dirty)
        logging.info("opened models from: %r", path)

        for key in parsed.keys():
            if type(parsed.get(key)) == list and len(parsed.get(key)) > 0:
                for index, el in enumerate(parsed.get(key)):
                    if type(el) == list:
                        el = [e for e in el if remove_rule(e)]
                        parsed[key][index] = el

        with open(path_of_cleaned_model, "w") as clean:
            clean.write(json.dumps(parsed))
    logging.info("wrote cleaned model at: %r", path_of_cleaned_model)


def main():
    # logging.basicConfig(filename ='C:\\Development\\TF\\Alpha\\covereter.log', level = logging.INFO, format = '%(levelname)s:%(asctime)s:%(message)s')

    # logging.info("Starting conversion process")
    # cleaner(path_of_composed_model)

    with open(path_of_cleaned_model, "r") as clean:
        parsed = json.load(clean)

        kind = Cpp
        converter = kind(
            "C:\\Development\\TF\\Alpha\\alpha-rascal\\models\\composed\\", parsed, None
        )

        converter.export("Velox")
        print("exported!")


main()

# result = verify_integrity(path_of_vizualization)
# print(f"Missing IDs: {result}")
