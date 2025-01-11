from Neo4jDataBaseHandler import Neo4jConnection, Neo4jQueryHandler
import os

def lambda_handler(event, context):
    neo4j_uri = os.environ.get("NEO4J_URI")
    neo4j_user = os.environ.get("NEO4J_USER")
    neo4j_pwd = os.environ.get("NEO4J_PASSWD")

    conn = Neo4jConnection(neo4j_uri, neo4j_user, neo4j_pwd)

    try:
        conn.connect()
        query_handler = Neo4jQueryHandler(conn)

        user_name = event.get("user_name")
        if user_name is None:
            raise ValueError("El evento no contiene un campo 'user_name'.")

        owned_projects = query_handler.get_owned_projects(user_name)
        collaborating_projects = query_handler.get_collaborating_projects(user_name)
        common_collaborators = query_handler.get_common_collaborators(user_name)

        return {
            "statusCode": 200,
            "body": {
                "owned_projects": owned_projects,
                "collaborating_projects": collaborating_projects,
                "common_collaborators": common_collaborators
            }
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": str(e)
        }

    finally:
        conn.close()
