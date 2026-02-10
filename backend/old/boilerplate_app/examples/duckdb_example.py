import duckdb
from typing import List, Dict, Any
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text

console = Console()


def run_duckdb_query(query: str) -> List[Dict[str, Any]]:
    con = duckdb.connect(":memory:")
    result = con.execute(query).fetchall()
    columns = [desc[0] for desc in con.description]
    return [dict(zip(columns, row)) for row in result]


def create_sample_data():
    con = duckdb.connect(":memory:")
    con.execute("""
        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name VARCHAR,
            age INTEGER,
            city VARCHAR
        )
    """)
    con.execute("""
        INSERT INTO users VALUES
        (1, 'Alice', 30, 'New York'),
        (2, 'Bob', 25, 'San Francisco'),
        (3, 'Charlie', 35, 'Chicago'),
        (4, 'Diana', 28, 'Seattle')
    """)
    return con


def calculate_average_age(con: duckdb.DuckDBPyConnection) -> float:
    result = con.execute("SELECT AVG(age) as avg_age FROM users").fetchone()
    return result[0] if result else 0.0


def example_queries():
    con = create_sample_data()
    
    avg_age = calculate_average_age(con)
    panel = Panel(f"Average Age: {avg_age:.2f}", title="Statistics")
    console.print(panel)
    
    table = Table(title="Users Older Than 28")
    table.add_column("ID", style="cyan", width=4)
    table.add_column("Name", style="magenta")
    table.add_column("Age", style="green", width=4)
    table.add_column("City", style="yellow")
    
    results = con.execute("SELECT * FROM users WHERE age > 28").fetchall()
    for row in results:
        table.add_row(str(row[0]), row[1], str(row[2]), row[3])
    
    console.print(table)
    
    table2 = Table(title="Users by City")
    table2.add_column("City", style="cyan")
    table2.add_column("Count", style="green", width=6)
    
    results = con.execute("SELECT city, COUNT(*) as count FROM users GROUP BY city").fetchall()
    for row in results:
        table2.add_row(row[0], str(row[1]))
    
    console.print(table2)
    
    con.close()
