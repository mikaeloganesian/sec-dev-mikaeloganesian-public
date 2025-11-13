def test_create_movie(client):
    response = client.post(
        "/movies/",
        json={"title": "Test Movie", "year": 2023, "genre": "Sci-Fi"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Movie"
    assert "id" in data


def test_read_movies_empty(client):
    response = client.get("/movies/")
    assert response.status_code == 200
    assert response.json() == []


def test_read_single_movie(client):
    create_response = client.post(
        "/movies/",
        json={"title": "Test Movie 5", "year": 2005, "genre": "Drama"},
    )
    movie_id = create_response.json()["id"]

    response = client.get(f"/movies/{movie_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Test Movie 5"
    assert response.json()["year"] == 2005


def test_delete_movie(client):
    create_response = client.post(
        "/movies/",
        json={"title": "To Delete Movie", "year": 1999, "genre": "Horror"},
    )
    movie_id = create_response.json()["id"]

    delete_response = client.delete(f"/movies/{movie_id}")
    assert delete_response.status_code == 204

    read_response = client.get(f"/movies/{movie_id}")
    assert read_response.status_code == 404
