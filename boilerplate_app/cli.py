import click
import sh
from typing import Optional, Dict, Any
from rich.console import Console
from rich.panel import Panel
from rich.text import Text

console = Console()


class AppError(Exception):
    """Custom exception for application errors."""
    pass


def get_system_info() -> Dict[str, Any]:
    """
    Gather system information using sh library.

    Returns:
        Dictionary with system information
    """
    try:
        info = {}

        info["username"] = sh.whoami().strip()

        info["hostname"] = sh.hostname().strip()

        info["date"] = sh.date().strip()

        info["python_version"] = sh.python("--version", _err_to_out=True).strip()

        return info

    except sh.ErrorReturnCode as e:
        raise AppError(f"Failed to gather system info: {e}")


def format_output(message: str, system_info: Dict[str, Any]) -> Panel:
    """
    Format the output for display.

    Args:
        message: The main message to display
        system_info: System information dictionary

    Returns:
        Rich Panel object for display
    """
    content = Text.assemble(
        (f"{message}\n\n", "bold green"),
        ("System Information:\n", "bold"),
    )

    for key, value in system_info.items():
        content.append(f"  {key}: ", "cyan")
        content.append(f"{value}\n", "white")

    return Panel(
        content,
        title="Agentic Boilerplate",
        border_style="blue",
        padding=(1, 2)
    )


@click.group()
def app():
    """A boilerplate CLI application demonstrating modern Python tooling."""
    pass


@app.command()
@click.option(
    "--message",
    default="Hello, World!",
    help="Message to display",
    show_default=True
)
@click.option(
    "--json",
    "json_output",
    is_flag=True,
    help="Output parsable JSON instead of formatted output"
)
def run(message: str, json_output: bool) -> None:
    """
    Run the boilerplate application with system information.
    
    This command showcases:
    - Click for CLI interface
    - Rich for terminal formatting
    - sh library for subprocess calls
    """

    try:
        system_info = get_system_info()

        if json_output:
            import json
            output = {
                "message": message,
                "system_info": system_info
            }
            console.print(json.dumps(output, indent=2))
        else:
            formatted_panel = format_output(message, system_info)
            console.print(formatted_panel)

    except AppError as e:
        console.print(f"Error: {e}", style="red")
        raise click.ClickException(str(e))
    except Exception as e:
        console.print(f"Unexpected error: {e}", style="red")
        raise click.ClickException(f"Unexpected error: {e}")


@app.command()
def demo_duckdb():
    """Demonstrate DuckDB functionality with sample queries."""
    from boilerplate_app.duckdb_example import example_queries
    console.print("[bold cyan]DuckDB Example:[/bold cyan]\n")
    example_queries()


@app.command()
def demo_polars():
    """Demonstrate Polars functionality with DataFrame operations."""
    from boilerplate_app.polars_example import example_dataframe_operations, example_data_transformation
    console.print("[bold cyan]Polars Example:[/bold cyan]\n")
    example_dataframe_operations()
    example_data_transformation()


@app.command()
def demo_cattrs():
    """Demonstrate cattrs functionality with dataclass serialization."""
    from boilerplate_app.cattrs_example import (
        example_basic_serialization,
        example_list_serialization,
        example_nested_dataclasses,
        example_json_serialization
    )
    console.print("[bold cyan]Cattrs Example:[/bold cyan]\n")
    example_basic_serialization()
    example_list_serialization()
    example_nested_dataclasses()
    example_json_serialization()


if __name__ == "__main__":
    app()
