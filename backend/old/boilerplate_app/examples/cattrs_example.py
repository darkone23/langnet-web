import cattrs
import json
from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.json import JSON
from rich.syntax import Syntax
from rich.text import Text

console = Console()


@dataclass
class User:
    id: int
    name: str
    age: int
    city: str
    email: Optional[str] = None


@dataclass
class Company:
    name: str
    users: List[User] = field(default_factory=list)


def example_basic_serialization():
    user = User(id=1, name="Alice", age=30, city="New York", email="alice@example.com")
    
    converter = cattrs.Converter()
    user_dict = converter.unstructure(user)
    
    console.print(Panel(Text.assemble(("Basic Serialization\n\n", "bold cyan"), ("Original:", "yellow"), f"\n{user}\n\n", ("Serialized to dict:", "yellow")), title="Cattrs Demo"))
    
    console.print(Syntax(json.dumps(user_dict, indent=2), "json", theme="monokai", line_numbers=True))
    
    user_restored = converter.structure(user_dict, User)
    console.print(f"\n[green]Restored:[/green] {user_restored}")


def example_list_serialization():
    users = [
        User(id=1, name="Alice", age=30, city="New York"),
        User(id=2, name="Bob", age=25, city="San Francisco"),
        User(id=3, name="Charlie", age=35, city="Chicago")
    ]
    
    converter = cattrs.Converter()
    users_list = converter.unstructure(users)
    
    console.print(Panel(Text.assemble(("List Serialization\n\n", "bold cyan"), ("Original:", "yellow"), f"\n{users}\n\n", ("Serialized:", "yellow")), title="Cattrs Demo"))
    
    console.print(Syntax(json.dumps(users_list, indent=2), "json", theme="monokai", line_numbers=True))
    
    users_restored = converter.structure(users_list, List[User])
    table = Table(title="Restored Users")
    table.add_column("ID", style="cyan", width=4)
    table.add_column("Name", style="magenta")
    table.add_column("Age", style="green", width=4)
    table.add_column("City", style="yellow")
    
    for user in users_restored:
        table.add_row(str(user.id), user.name, str(user.age), user.city)
    
    console.print(table)


def example_nested_dataclasses():
    company = Company(
        name="Tech Corp",
        users=[
            User(id=1, name="Alice", age=30, city="New York"),
            User(id=2, name="Bob", age=25, city="San Francisco")
        ]
    )
    
    converter = cattrs.Converter()
    company_dict = converter.unstructure(company)
    
    console.print(Panel(Text.assemble(("Nested Dataclass Serialization\n\n", "bold cyan"), ("Original:", "yellow"), f"\n{company}\n\n", ("Serialized:", "yellow")), title="Cattrs Demo"))
    
    console.print(Syntax(json.dumps(company_dict, indent=2), "json", theme="monokai", line_numbers=True))
    
    company_restored = converter.structure(company_dict, Company)
    console.print(f"\n[green]Restored:[/green] {company_restored}")


def example_json_serialization():
    user = User(id=1, name="Alice", age=30, city="New York", email="alice@example.com")
    
    converter = cattrs.Converter()
    user_dict = converter.unstructure(user)
    user_json = json.dumps(user_dict, indent=2)
    
    console.print(Panel(Text.assemble(("JSON Serialization\n\n", "bold cyan"), ("Original:", "yellow"), f"\n{user}\n\n", ("Serialized to JSON:", "yellow")), title="Cattrs Demo"))
    
    console.print(Syntax(user_json, "json", theme="monokai", line_numbers=True))
    
    user_from_json = json.loads(user_json)
    user_restored = converter.structure(user_from_json, User)
    console.print(f"\n[green]Restored from JSON:[/green] {user_restored}")
