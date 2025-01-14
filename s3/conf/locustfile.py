import os
from locust import HttpUser, task, between

class APIUser(HttpUser):
    host = os.getenv("BACKEND_IP")
    host = f"http://{host}"
    wait_time = between(1, 3)

    @task
    def get_users(self):
        """Prueba el endpoint /users."""
        self.client.get("/users")

    @task
    def get_user(self):
        """Prueba el endpoint /user/<user_id>."""
        user_id = "User_100"
        self.client.get(f"/user/{user_id}")

    @task
    def get_user_projects(self):
        """Prueba el endpoint /user/<user_id>/projects."""
        user_id = "User_100"
        self.client.get(f"/user/{user_id}/projects")

    @task
    def get_user_collaborations(self):
        """Prueba el endpoint /user/<user_id>/collaborations."""
        user_id = "User_100"
        self.client.get(f"/user/{user_id}/collaborations")

    @task
    def get_projects(self):
        """Prueba el endpoint /projects."""
        self.client.get("/projects")

    @task
    def get_project_details(self):
        """Prueba el endpoint /project/<project_id>."""
        project_id = "Project_200"
        self.client.get(f"/project/{project_id}")

    @task
    def get_project_owner(self):
        """Prueba el endpoint /project/<project_id>/owner."""
        project_id = "Project_200"
        self.client.get(f"/project/{project_id}/owner")

    @task
    def get_project_collaborators(self):
        """Prueba el endpoint /project/<project_id>/collaborators."""
        project_id = "Project_200"
        self.client.get(f"/project/{project_id}/collaborators")