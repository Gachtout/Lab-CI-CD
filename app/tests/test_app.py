import pytest

import app as lab


@pytest.fixture()
def client(tmp_path, monkeypatch):
    monkeypatch.setattr(lab, "DB_PATH", str(tmp_path / "test.db"))
    return lab.create_app().test_client()


def test_health(client):
    assert client.get("/health").get_json() == {"status": "ok"}


def test_utilisateur_existant(client):
    data = client.get("/users?name=alice").get_json()
    assert data["result"] == [{"id": 1, "name": "alice", "role": "admin"}]


def test_injection_sql_sans_effet(client):
    # Avec une requête paramétrée, la charge est cherchée comme un nom : aucun résultat.
    data = client.get("/users?name=x' OR '1'='1").get_json()
    assert data["result"] == []
