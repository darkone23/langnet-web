default:
    @just run

run:
    uv run --active boilerplate-cli run

run-custom:
    uv run --active boilerplate-cli run --message "Custom message!"

run-json:
    uv run --active boilerplate-cli run --json

demo-duckdb:
    uv run --active boilerplate-cli demo-duckdb

demo-polars:
    uv run --active boilerplate-cli demo-polars

demo-cattrs:
    uv run --active boilerplate-cli demo-cattrs

# enter the core developer session
devenv-zell:
    devenv shell bash -- -c "zell"
