import logging

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from starlette.status import HTTP_422_UNPROCESSABLE_ENTITY

from .db.database import Base, engine
from .handlers import courseHandlers, movieHandlers
from .utils.errors import problem

logger = logging.getLogger("uvicorn")

app = FastAPI(title="Movies/Courses catalog", version="0.1.0")

Base.metadata.create_all(bind=engine)


@app.get("/test-500-error")
def trigger_internal_error():
    raise Exception("Тестовая внутренняя ошибка для проверки ADR-002")


@app.exception_handler(Exception)
async def catch_all_exception_handler(request: Request, exc: Exception):
    logger.error("Непредвиденная ошибка", exc_info=True)

    return problem(
        status=500,
        title="Internal Server Error",
        detail="Произошла внутренняя ошибка сервера. Пожалуйста, попробуйте позже.",
        type_="https://example.com/probs/internal-error",
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return problem(
        status=exc.status_code,
        title=exc.detail,
        detail=exc.detail,
        type_=f"https://example.com/probs/http-{exc.status_code}",
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    return problem(
        status=HTTP_422_UNPROCESSABLE_ENTITY,
        title="Validation Error",
        detail="Ошибка в формате или содержимом входных данных.",
        type_="https://example.com/probs/validation-error",
        extras={"errors": exc.errors()},
    )


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/")
def read_root():
    return {
        "message": "Welcome to the Movies/Courses Catalog API! Check /docs for available endpoints."
    }


app.include_router(courseHandlers.router, prefix="/courses", tags=["courses"])
app.include_router(movieHandlers.router, prefix="/movies", tags=["movies"])
