def test_read_root(client):
    response = client.get("/")
    assert response.status_code == 200
    assert "Welcome" in response.json()["message"]


def test_create_course(client):
    response = client.post(
        "/courses/",
        json={
            "title": "Test Course",
            "platform": "Test Platform",
            "duration_hours": 10,
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Course"
    assert "id" in data


def test_read_courses_empty(client):
    response = client.get("/courses/")
    assert response.status_code == 200
    assert response.json() == []


def test_read_courses_list(client):
    client.post(
        "/courses/",
        json={"title": "Another Course", "platform": "P2", "duration_hours": 5},
    )

    response = client.get("/courses/")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert response.json()[0]["title"] == "Another Course"


def test_read_single_course(client):
    create_response = client.post(
        "/courses/",
        json={"title": "Single Course", "platform": "P3", "duration_hours": 20},
    )
    course_id = create_response.json()["id"]

    response = client.get(f"/courses/{course_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Single Course"


def test_delete_course(client):
    create_response = client.post(
        "/courses/",
        json={"title": "To Delete", "platform": "P4", "duration_hours": 1},
    )
    course_id = create_response.json()["id"]

    delete_response = client.delete(f"/courses/{course_id}")
    assert delete_response.status_code == 204

    read_response = client.get(f"/courses/{course_id}")
    assert read_response.status_code == 404
