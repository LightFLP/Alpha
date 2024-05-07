def parse_rascal_problem_location(rascal_problem_location):
    """
    Parses a Rascal |problem:///| location value and extracts relevant information.

    Args:
        rascal_location (str): The Rascal location value.

    Returns:
        dict: A dictionary containing the extracted information.
            - 'id': The ID following 'problem:///'.
            - 'message': The error message.
    """
    try:
        # Remove the "problem://" prefix
        cleaned_location = rascal_problem_location.replace("problem:///", "")

        # Split the remaining part using "?message="
        id_and_message = cleaned_location.split("?message=")

        if len(id_and_message) == 2:
            # Extract the ID and message
            location_id, error_message = id_and_message

            error_message = error_message.replace("%20", " ")
            error_message_list = error_message.split(":")
            if len(error_message_list) == 2:
                error_object = error_message_list[1].replace(" ", "")
            else:
                error_object = ""

            return {
                'id': location_id,
                'message': error_message,
                'object': error_object
            }
        else:
            return None  # Invalid format
    except Exception as e:
        print(f"Error parsing Rascal location: {e}")
        return None

# Example usage:
# rascal_location_value = "problem:///cc6bd1ac-0be4-44d2-98d8-1f08ac44c5db?message=A%20declaration%20could%20not%20be%20found%20for%20this%20member%20definition:%20CoBhvStage3Brick"
# parsed_info = parse_rascal_problem_location(rascal_location_value)

# if parsed_info:
#     print(f"ID: {parsed_info['id']}")
#     print(f"Message: {parsed_info['message']}")
#     print(f"Object: {parsed_info['object']}")
# else:
#     print("Invalid Rascal location format.")
