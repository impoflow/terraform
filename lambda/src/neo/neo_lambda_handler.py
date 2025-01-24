from Neo4jDataBaseHandler import Neo4jConnection, Neo4jQueryHandler
import os
import re

def lambda_handler(event, context):
    neo4j_uri = os.environ.get("NEO4J_URI")
    neo4j_user = os.environ.get("NEO4J_USER")
    neo4j_pwd = os.environ.get("NEO4J_PASSWORD")

    conn = Neo4jConnection(neo4j_uri, neo4j_user, neo4j_pwd)

    try:
        conn.connect()
        query_handler = Neo4jQueryHandler(conn)

        route = event.get("route", "")
        handlers = {
            "/reports": lambda: query_handler.get_report(),
            "/users": lambda: query_handler.get_users(),
            "/projects": lambda: query_handler.get_projects()
        }

        if route.startswith("/users/") or route.startswith("/users?"):
            return handle_user_routes(route, query_handler)

        if route.startswith("/projects/") or route.startswith("/projects?"):
            return handle_project_routes(route, query_handler)

        if route in handlers:
            response = handlers[route]()
            return {"statusCode": 200, "body": response}

        return {"statusCode": 404, "body": "Route not found"}

    except Exception as e:
        return {"statusCode": 500, "body": str(e)}

    finally:
        conn.close()

def handle_user_routes(route, query_handler):
    elements = route.split("/")
    if len(elements) > 2:
        user_name = elements[2]

    if route.endswith("/projects"):
        response = query_handler.get_owned_projects(user_name)

    elif route.endswith("/collaborations"):
        response = query_handler.get_collaborating_projects(user_name)

    elif route.endswith("/collaborators"):
        response = query_handler.get_common_collaborators(user_name)

    elif "?isolated=true" in route:
        response = query_handler.get_users_without_projects()

    elif "?degree=" in route:
        response = handle_users_by_degree(route, query_handler)

    elif "/shortest_path?" in route:
        response = handle_shortest_path(route, query_handler)

    elif "/all_paths?" in route:
        response = handle_all_paths(route, query_handler)

    elif route.endswith("?most_distant=true"):
        response = query_handler.most_distant_users()

    elif route.endswith("/clusters"):
        response = query_handler.detect_clusters()

    else:
        response = {
            "owned_projects": query_handler.get_owned_projects(user_name),
            "collaborating_projects": query_handler.get_collaborating_projects(user_name),
            "common_collaborators": query_handler.get_common_collaborators(user_name)
        }
    return {"statusCode": 200, "body": response}

def handle_project_routes(route, query_handler):
    elements = route.split("/")
    if len(elements) > 2:
        project_id = route.split("/")[2]

    if route.endswith("/owner"):
        response = query_handler.get_project_owner(project_id)

    elif route.endswith("/classes"):
        response = query_handler.get_project_classes(project_id)

    elif route.endswith("/collaborators"):
        response = query_handler.get_project_collaborators(project_id)

    elif route.endswith("/isolated_classes"):
        owner = query_handler.get_project_owner(project_id)
        response = query_handler.isolated_classes_in_project(project_id, owner[0])

    elif '?degree=' in route:
        response = handle_projects_by_degree(route, query_handler)

    elif route.endswith("/clusters"):
        response = query_handler.detect_most_connected_projects()

    else:
        owner = query_handler.get_project_owner(project_id)
        classes = query_handler.get_project_classes(project_id)
        collaborators = query_handler.get_project_collaborators(project_id)
        isolated_classes = query_handler.get_isolated_classes(project_id, owner[0])

        response = {
            "owner": owner,
            "classes": classes,
            "collaborators": collaborators,
            "isolated_classes": isolated_classes
        }
    return {"statusCode": 200, "body": response}

def handle_shortest_path(route, query_handler):
    match = re.search(r"/users/([^&]+)/shortest_path\?user=([^&]+)", route)

    if match:
        user1 = match.group(1)
        user2 = match.group(2)
        response = query_handler.shortest_path_between_users(user1, user2)
        return {"statusCode": 200, "body": response}

    else:
        return {"statusCode": 400, "body": "Bad Request"}

def handle_all_paths(route, query_handler):
    match = re.search(r"/users/([^&]+)/all_paths\?user=([^&]+)&max_depth=([^&]+)", route)

    if match:
        user1 = match.group(1)
        user2 = match.group(2)
        n = match.group(3)
        response = query_handler.all_paths_between_users(user1, user2, max_depth=n)
        return {"statusCode": 200, "body": response}

    else:
        return {"statusCode": 400, "body": "Bad Request"}

def handle_users_by_degree(route, query_handler):
    match = re.search(r"degree=([^&]+)", route)

    if match:
        degree = match.group(1)
        response = query_handler.select_users_by_degree(degree)
        return {"statusCode": 200, "body": response}

    else:
        return {"statusCode": 400, "body": "Bad Request"}

def handle_projects_by_degree(route, query_handler):
    match = re.search(r"degree=([^&]+)", route)

    if match:
        degree = match.group(1)
        response = query_handler.select_projects_by_degree(degree)
        return {"statusCode": 200, "body": response}

    else:
        return {"statusCode": 400, "body": "Bad Request"}