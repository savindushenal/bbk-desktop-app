"""PyInstaller hook for FastAPI"""
from PyInstaller.utils.hooks import collect_all, collect_submodules

# Collect all fastapi modules
datas, binaries, hiddenimports = collect_all('fastapi')

# Add additional hidden imports
hiddenimports += [
    'fastapi.applications',
    'fastapi.routing',
    'fastapi.params',
    'fastapi.encoders',
    'fastapi.exceptions',
    'fastapi.middleware',
    'fastapi.middleware.cors',
]

# Collect starlette (required by fastapi)
starlette_datas, starlette_binaries, starlette_hidden = collect_all('starlette')
datas += starlette_datas
binaries += starlette_binaries
hiddenimports += starlette_hidden

# Collect pydantic (required by fastapi)
pydantic_datas, pydantic_binaries, pydantic_hidden = collect_all('pydantic')
datas += pydantic_datas
binaries += pydantic_binaries
hiddenimports += pydantic_hidden

# Collect uvicorn
uvicorn_datas, uvicorn_binaries, uvicorn_hidden = collect_all('uvicorn')
datas += uvicorn_datas
binaries += uvicorn_binaries
hiddenimports += uvicorn_hidden
