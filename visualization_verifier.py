import json

def verify_integrity(path_of_viz_json):
    try:
        with open(path_of_viz_json, "r") as viz:
            # Parse the JSON data
            parsed_data = json.load(viz)
            
            # Extract nodes and edges arrays
            elements = parsed_data.get("elements", {})
            nodes = elements.get("nodes", [])
            edges = elements.get("edges", [])
            
            # Extract 'id' values from nodes and edges
            node_ids = set(node.get("data").get("id") for node in nodes)

            edge_source_ids = set(edge.get("data").get("source") for edge in edges)
            edge_target_ids = set(edge.get("data").get("target") for edge in edges)
            node_ids_in_edges = edge_source_ids | edge_target_ids
            
            # Find the difference between node_ids and edge_ids
            missing_ids = list(node_ids.symmetric_difference(node_ids_in_edges))
        
        return missing_ids
    except Exception as e:
        return f"Error: {str(e)}"

