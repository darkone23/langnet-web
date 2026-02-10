import os
from pathlib import Path
from contextlib import asynccontextmanager
from starlette.applications import Starlette
from starlette.responses import Response
from starlette.routing import Route, Mount
from starlette.staticfiles import StaticFiles
from starlette.templating import Jinja2Templates
from boilerplate_app.web.routes import api_routes

@asynccontextmanager
async def lifespan(app: Starlette):
    app.state.db = None
    yield

def create_app():
    static_dir = Path(__file__).parent.parent.parent.parent / 'frontend' / 'dist'
    templates = Jinja2Templates(directory=Path(__file__).parent / 'templates')
    
    routes = [
        Mount('/api', routes=api_routes),
        Mount('/assets', app=StaticFiles(directory=str(static_dir / 'assets')), name='assets'),
        Route('/vite.svg', lambda r: Response(content=open(static_dir / 'vite.svg', 'rb').read(), media_type='image/svg+xml')),
        Route('/', lambda r: Response(content=open(static_dir / 'index.html', 'rb').read(), media_type='text/html')),
    ]
    
    app = Starlette(lifespan=lifespan, routes=routes)
    
    return app