from neo4j import GraphDatabase

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

    def get_common_collaborators(self, user1):
        query = """
        MATCH (u1:User {name: $user1})-[:COLLABORATES_IN|OWNS]->(p:Project)<-[:COLLABORATES_IN|OWNS]-(u2:User)
        WHERE u1.name <> u2.name
        RETURN DISTINCT u2.name AS collaborator_name
        """
        with self.driver.session() as session:
            result = session.run(query, user1=user1)
            return [record["collaborator_name"] for record in result]
        
    def get_project_classes(self, project):
        query = """
        MATCH (p:Project {name: $project})<-[:MAIN]-(main_class:Class)
        MATCH path = (main_class)-[:IMPORTS|IMPLEMENTS*]->(c:Class)
        RETURN DISTINCT c.name AS class_name
        """
        with self.driver.session() as session:
            result = session.run(query, project=project)
            return [record["class_name"] for record in result]

    def get_project_collaborators(self, project):
        query = """
        MATCH (p:Project {name: $project})<-[:COLLABORATES_IN]-(u:User)
        RETURN DISTINCT u.name AS collaborator_name
        """
        with self.driver.session() as session:
            result = session.run(query, project=project)
            return [record["collaborator_name"] for record in result]
        
    def get_project_owner(self, project):
        query = """
        MATCH (u:User)-[:OWNS]->(p:Project {name: $project})
        RETURN u.name AS owner_name
        """
        with self.driver.session() as session:
            result = session.run(query, project=project)
            return [record["owner_name"] for record in result]