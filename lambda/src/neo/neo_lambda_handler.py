from Neo4jDataBaseHandler import Neo4jConnection, Neo4jQueryHandler
import os

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
            "/projects": lambda: query_handler.get_projects()
        }

        if route.startswith("/user/"):
            return handle_user_routes(route, query_handler)

        if route.startswith("/project/"):
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
    """Manejo de rutas relacionadas con usuarios."""
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
    """Manejo de rutas relacionadas con proyectos."""
    project_id = route.split("/")[2]

    if route.endswith("/owner"):
        response = query_handler.get_project_owner(project_id)
    elif route.endswith("/classes"):
        response = query_handler.get_project_classes(project_id)
    elif route.endswith("/collaborators"):
        response = query_handler.get_project_collaborators(project_id)
    else:
        response = {
            "owner": query_handler.get_project_owner(project_id),
            "classes": query_handler.get_project_classes(project_id),
            "collaborators": query_handler.get_project_collaborators(project_id)
        }
    return {"statusCode": 200, "body": response}
