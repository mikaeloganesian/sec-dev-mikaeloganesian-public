import importlib
import os

import pytest
from fastapi.testclient import TestClient

import app.db.database
import app.main
from app.utils.errors import problem

client = TestClient(app.main.app)


def test_not_found_item_rfc7807():
    r = client.get("/movies/99999")

    assert r.status_code == 404
    assert r.headers["content-type"] == "application/problem+json"

    body = r.json()
    assert body["status"] == 404
    assert "correlation_id" in body
    assert body["title"] == "Фильм не найден"


def test_rejects_invalid_input_422_rfc7807():
    invalid_data = {"title": "A" * 101, "year": 1800, "genre": "Action<script>"}
    r = client.post("/movies/", json=invalid_data)

    assert r.status_code == 422
    assert "application/problem+json" in r.headers["content-type"]

    body = r.json()
    assert body["status"] == 422
    assert "errors" in body
    assert body["title"] == "Validation Error"

    error_fields = [err["loc"][1] for err in body["errors"]]
    assert "title" in error_fields
    assert "genre" in error_fields
    assert "year" in error_fields


def test_internal_server_error_is_masked():
    response = problem(
        status=500,
        title="Internal Server Error",
        detail="Произошла внутренняя ошибка сервера. Пожалуйста, попробуйте позже.",
        type_="https://example.com/probs/internal-error",
    )

    assert response.status_code == 500
    assert response.headers["Content-Type"] == "application/problem+json"

    body = response.body.decode("utf-8")
    assert "Произошла внутренняя ошибка сервера" in body
    assert "Тестовая внутренняя ошибка" not in body


def test_db_secret_env_only():
    original_value = os.environ.pop("DATABASE_URL", None)

    try:
        with pytest.raises(OSError, match="DATABASE_URL"):
            importlib.reload(app.db.database)
            pass
    finally:
        if original_value is not None:
            os.environ["DATABASE_URL"] = original_value
