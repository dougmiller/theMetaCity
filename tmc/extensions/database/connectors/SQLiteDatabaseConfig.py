class SQLiteDatabaseConfig:
    def __init__(self, path: str = "DATABASE") -> None:
        self.path = path
        self.DATABASE_URI = f"sqlite:///{self.path}"
