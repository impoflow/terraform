from neo4j import GraphDatabase
import os

class Neo4jConnection:
    def __init__(self, uri, user, pwd):
        self._uri = uri
        self._user = user
        self._pwd = pwd
        self._driver = None

    def connect(self):
        self._driver = GraphDatabase.driver(self._uri, auth=(self._user, self._pwd))

    def close(self):
        if self._driver is not None:
            self._driver.close()

class Neo4jQueryHandler:
    def __init__(self, connection):
        self.driver = connection._driver

    def close(self):
        self.driver.close()

    def get_owned_projects(self, user_name):
        query = """
        MATCH (u:User {name: $user_name})-[:OWNS]->(p:Project)
        RETURN p.name AS project_name
        """
        with self.driver.session() as session:
            result = session.run(query, user_name=user_name)
            return [record["project_name"] for record in result]

    def get_collaborating_projects(self, user_name):
        query = """
        MATCH (u:User {name: $user_name})-[:COLLABORATES_IN]->(p:Project)
        RETURN p.name AS project_name
        """
        with self.driver.session() as session:
            result = session.run(query, user_name=user_name)
            return [record["project_name"] for record in result]

    def get_common_collaborators(self, user1, user2):
        query = """
        MATCH (u1:User {name: $user1})-[:COLLABORATES_IN]->(p:Project)<-[:COLLABORATES_IN]-(u2:User)
        MATCH (u2)-[:COLLABORATES_IN]->(p:Project)<-[:COLLABORATES_IN]-(u1)
        WHERE u2.name <> $user1 AND u2.name <> $user2
        RETURN DISTINCT u2.name AS collaborator_name
        """
        with self.driver.session() as session:
            result = session.run(query, user1=user1, user2=user2)
            return [record["collaborator_name"] for record in result]


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
        common_collaborators = query_handler.get_common_collaborators("Alice", "Bob")

        return {
            "statusCode": 200,
            "body": {
                "owned_projects": owned_projects,
                "collaborating_projects": collaborating_projects,
                "common_collaborators": common_collaborators
            }
        }