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
            "/users": lambda: query_handler.get_users(),
            "/projects": lambda: query_handler.get_projects(),
            "/clusters": lambda: query_handler.detect_clusters(),
            "/highly_connected_users": lambda: query_handler.get_highly_connected_users(),
            "/highly_connected_projects": lambda: query_handler.get_highly_connected_projects(),
        }

        if route.startswith("/user/"):
            return handle_user_routes(route, query_handler)

        if route.startswith("/project/"):
            return handle_project_routes(route, query_handler)

        if route.startswith("/shortest_path"):
            return handle_shortest_path(event, query_handler)

        if route.startswith("/all_paths"):
            return handle_all_paths(event, query_handler)

        if route in handlers:
            response = handlers[route]()
            return {"statusCode": 200, "body": response}

        return {"statusCode": 404, "body": "Route not found"}

    except Exception as e:
        return {"statusCode": 500, "body": str(e)}

    finally:
        conn.close()

def handle_user_routes(route, query_handler):
    user_name = route.split("/")[2]

    if route.endswith("/projects"):
        response = query_handler.get_owned_projects(user_name)
    elif route.endswith("/collaborations"):
        response = query_handler.get_collaborating_projects(user_name)
    elif route.endswith("/collaborators"):
        response = query_handler.get_common_collaborators(user_name)
    else:
        response = {
            "owned_projects": query_handler.get_owned_projects(user_name),
            "collaborating_projects": query_handler.get_collaborating_projects(user_name),
            "common_collaborators": query_handler.get_common_collaborators(user_name)
        }
    return {"statusCode": 200, "body": response}

def handle_project_routes(route, query_handler):
    project_id = route.split("/")[2]

    if route.endswith("/owner"):
        response = query_handler.get_project_owner(project_id)
    elif route.endswith("/classes"):
        response = query_handler.get_project_classes(project_id)
    elif route.endswith("/collaborators"):
        response = query_handler.get_project_collaborators(project_id)
    elif route.endswith("/isolated_classes"):
        response = query_handler.isolated_classes_in_project(project_id)
    else:
        response = {
            "owner": query_handler.get_project_owner(project_id),
            "classes": query_handler.get_project_classes(project_id),
            "collaborators": query_handler.get_project_collaborators(project_id)
        }
    return {"statusCode": 200, "body": response}

def handle_shortest_path(event, query_handler):
    route = event.get("route", "")
    match = re.search(r"user1=([^&]+)&user2=([^&]+)", route)

    if match:
        user1 = match.group(1)
        user2 = match.group(2)

        print(user1)
        print(user2)

        print(user1, user2)
        response = query_handler.shortest_path_between_users(user1, user2)
        print(response)
        return {"statusCode": 200, "body": response}

    else:
        return {"statusCode": 400, "body": "Bad Request"}

def handle_all_paths(event, query_handler):
    route = event.get("route", "")
    match = re.search(r"user1=([^&]+)&user2=([^&]+)&max_depth=([^&]+)", route)

    if match:
        user1 = match.group(1)
        user2 = match.group(2)
        n = match.group(3)

        print(user1)
        print(user2)
        print(n)

        print(user1, user2)
        response = query_handler.all_paths_between_users(user1, user2, max_depth=n)
        return {"statusCode": 200, "body": response}

    else:
        return {"statusCode": 400, "body": "Bad Request"}