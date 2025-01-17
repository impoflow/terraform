from packages.neo4j import GraphDatabase

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

    def get_users(self):
        query = """
        MATCH (u:User)
        RETURN u.name AS user_name
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [record["user_name"] for record in result]

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
    
    def get_projects(self):
        query = """
        MATCH (p:Project)
        RETURN p.name AS project_name
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [record["project_name"] for record in result]
        
    def get_project_owner(self, project):
        query = """
        MATCH (u:User)-[:OWNS]->(p:Project {name: $project})
        RETURN u.name AS owner_name
        """
        with self.driver.session() as session:
            result = session.run(query, project=project)
            return [record["owner_name"] for record in result]
        
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

    def shortest_path_between_users(self, user1, user2):
        query = """
        MATCH (u1:User {name: $user1}), (u2:User {name: $user2})
        MATCH path = shortestPath((u1)-[:OWNS|COLLABORATES_IN*]-(u2))
        UNWIND nodes(path) AS n
        WITH n
        WHERE 'User' IN labels(n)
        RETURN DISTINCT n.name AS user_name
        """
        with self.driver.session() as session:
            result = session.run(query, user1=user1, user2=user2)
            return [record["user_name"] for record in result]

    def all_paths_between_users(self, user1, user2, max_depth=5):
        query = f"""
        MATCH (u1:User {{name: $user1}}), (u2:User {{name: $user2}})
        MATCH path = (u1)-[:OWNS|COLLABORATES_IN*1..{max_depth}]-(u2)
        UNWIND nodes(path) AS n
        WITH n
        WHERE 'User' IN labels(n)
        RETURN DISTINCT n.name AS user_name
        """
        
        with self.driver.session() as session:
            result = session.run(query, user1=user1, user2=user2)
            return [record["user_name"] for record in result]

    def isolated_classes_in_project(self, project_name, owner):
        query = """
        MATCH (c:Class {project: $project_name, user: $owner})
        WHERE NOT (c)--()
        RETURN c.name AS class
        """
        with self.driver.session() as session:
            result = session.run(query, project_name=project_name, owner=owner)
            return [record["class"] for record in result]

    def detect_clusters(self):
        query = """
        CALL algo.louvain.stream("User", "COLLABORATES_IN")
        YIELD nodeId, community
        RETURN algo.asNode(nodeId).name AS user, community
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [{"user": record["user"], "community": record["community"]} for record in result]

    def get_highly_connected_users(self):
        query = """
        MATCH (u:User)-[r]-()
        RETURN u.name AS user, COUNT(r) AS connections
        ORDER BY connections DESC
        LIMIT 5
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [{"user": record["user"], "connections": record["connections"]} for record in result]

    def get_highly_connected_projects(self):
        query = """
        MATCH (p:Project)<-[r]-()
        RETURN p.name AS project, COUNT(r) AS connections
        ORDER BY connections DESC
        LIMIT 5
        """
        with self.driver.session() as session:
            result = session.run(query)
            return [{"project": record["project"], "connections": record["connections"]} for record in result]

