from pathlib import Path
from starlette.responses import JSONResponse
from starlette.concurrency import run_in_threadpool
from starlette.routing import Route
from starlette.templating import Jinja2Templates
import polars as pl

templates = Jinja2Templates(directory=Path(__file__).parent / 'templates')

async def hello(request):
    return JSONResponse({'message': 'Hello from Starlette API!'})

async def hello_post(request):
    data = await request.json()
    return JSONResponse({'message': f'Hello, {data.get("name", "World")}!'})

async def hello_htmx(request):
    return templates.TemplateResponse('hello_htmx.html', {'request': request})

async def main_content(request):
    return templates.TemplateResponse('main_content.html', {'request': request})

async def duckdb_example(request):
    def query():
        db = request.app.state.db
        if db is None:
            df = pl.DataFrame({
                'name': ['Alice', 'Bob', 'Charlie'],
                'age': [25, 30, 35],
                'city': ['NYC', 'LA', 'Chicago']
            })
        else:
            df = db.sql("SELECT * FROM users").pl()
        return df.to_dicts()
    return JSONResponse(await run_in_threadpool(query))

async def polars_example(request):
    def process():
        df = pl.DataFrame({
            'product': ['A', 'B', 'C', 'D', 'E'],
            'price': [10.5, 25.0, 15.75, 30.0, 20.25],
            'quantity': [100, 50, 75, 25, 60]
        })
        summary = df.select([
            pl.col('product'),
            (pl.col('price') * pl.col('quantity')).alias('total')
        ])
        return summary.to_dicts()
    return JSONResponse(await run_in_threadpool(process))

api_routes = [
    Route('/hello', hello, methods=['GET']),
    Route('/hello', hello_post, methods=['POST']),
    Route('/hello-htmx', hello_htmx, methods=['GET']),
    Route('/main-content', main_content, methods=['GET']),
    Route('/duckdb-example', duckdb_example, methods=['GET']),
    Route('/polars-example', polars_example, methods=['GET']),
]