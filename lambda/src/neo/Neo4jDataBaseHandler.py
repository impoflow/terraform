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

    def get_users_without_projects(self):
        query = """
        MATCH (u:User)
        WHERE NOT (u)-[:OWNS]->(:Project)
        RETURN u.name AS user_name
        """
        with self.driver.session() as session:
            result = session.run(query)
            users_without_projects = []
            for record in result:
                users_without_projects.append(record['user_name'])

            return users_without_projects

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
        MATCH (c:Class {project: $project})
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

    def get_isolated_classes(self, project_name, owner):
        query = """
        MATCH (c:Class {project: $project_name, user: $owner})
        WHERE NOT (c)-[:IMPORTS|IMPLEMENTS|MAIN]->()
        AND NOT ()-[:IMPORTS|IMPLEMENTS|MAIN]->(c)
        RETURN c.name AS isolated_class
        """
        with self.driver.session() as session:
            result = session.run(query, project_name=project_name, owner=owner)
            isolated_classes = []
            for record in result:
                isolated_classes.append(record['isolated_class'])

            return isolated_classes

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
        MATCH path = (u1)-[:OWNS|COLLABORATES_IN*..{max_depth}]-(u2)
        RETURN DISTINCT path
        """
        
        with self.driver.session() as session:
            result = session.run(query, user1=user1, user2=user2)
            
            paths = []
            for record in result:
                path = record["path"]
                path_nodes = [node["name"] for node in path.nodes]
                paths.append(path_nodes)
            
            return paths

    def most_distant_users(self):
        query = """
        MATCH (u1:User), (u2:User)
        WHERE u1 <> u2
        MATCH path = (u1)-[:OWNS|COLLABORATES_IN*]-(u2)
        WITH u1, u2, path, length(path) AS path_length
        ORDER BY path_length DESC
        LIMIT 1
        RETURN u1.name AS user1, u2.name AS user2, path_length AS max_distance
        """
        
        with self.driver.session() as session:
            result = session.run(query)
            
            record = result.single()
            if record:
                return {
                    "user1": record["user1"],
                    "user2": record["user2"],
                    "max_distance": record["max_distance"]
                }
            else:
                return {
                    "user1": None,
                    "user2": None,
                    "max_distance": None
                }

    def detect_clusters(self):
        query = """
        MATCH (u1:User)-[:COLLABORATES_IN|OWNS]->(p:Project)<-[:COLLABORATES_IN|OWNS]-(u2:User)
        WITH u1, COLLECT(DISTINCT u2) AS connected_users
        RETURN u1.name AS user_name, SIZE(connected_users) AS cluster_size
        ORDER BY cluster_size DESC
        LIMIT 10
        """
        with self.driver.session() as session:
            result = session.run(query)
            clusters = []
            for record in result:
                clusters.append({
                    'user_name': record['user_name'],
                    'cluster_size': record['cluster_size']
                })
            return clusters

    def select_users_by_degree(self, degree):
        query = f"""
        MATCH (u:User)-[:COLLABORATES_IN|OWNS]->(p:Project)<-[:COLLABORATES_IN|OWNS]-(u2:User)
        WITH u, COUNT(DISTINCT u2) AS user_degree
        WHERE user_degree = {int(degree)}
        RETURN u.name AS user_name, user_degree
        """
        with self.driver.session() as session:
            result = session.run(query)
            users = []
            for record in result:
                users.append({
                    'user_name': record['user_name'],
                    'user_degree': record['user_degree']
                })

            return users


    def select_projects_by_degree(self, degree):
        query = f"""
        MATCH (p:Project)<-[:COLLABORATES_IN|OWNS]-(u:User)
        WITH p, COUNT(DISTINCT u) AS project_degree
        WHERE project_degree = {degree}
        RETURN p.name AS project_name, project_degree
        """
        with self.driver.session() as session:
            result = session.run(query)
            projects = []
            for record in result:
                projects.append({
                    'project_name': record['project_name'],
                    'project_degree': record['project_degree']
                })
            return projects

    def get_report(self):
        query = """
        MATCH (u:User)
        WITH COUNT(u) AS num_users
        MATCH (p:Project)
        WITH num_users, COUNT(p) AS num_projects
        MATCH (c:Class)
        WITH num_users, num_projects, COUNT(c) AS num_classes
        MATCH ()-[r:OWNS]->()
        WITH num_users, num_projects, num_classes, COUNT(r) AS num_owns
        MATCH ()-[r:COLLABORATES_IN]->()
        WITH num_users, num_projects, num_classes, num_owns, COUNT(r) AS num_collaborates_in
        MATCH ()-[r:IMPORTS]->()
        WITH num_users, num_projects, num_classes, num_owns, num_collaborates_in, COUNT(r) AS num_imports
        MATCH ()-[r:IMPLEMENTS]->()
        RETURN num_users, num_projects, num_classes, num_owns, num_collaborates_in, num_imports, COUNT(r) AS num_implements
        """
        with self.driver.session() as session:
            result = session.run(query)
            record = result.single()
            return {
                'num_users': record['num_users'],
                'num_projects': record['num_projects'],
                'num_classes': record['num_classes'],
                'num_owns': record['num_owns'],
                'num_collaborates_in': record['num_collaborates_in'],
                'num_imports': record['num_imports'],
                'num_implements': record['num_implements']
            }