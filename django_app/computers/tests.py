import pytest
from rest_framework.test import APIClient

from computers.models import Computer

pytestmark = pytest.mark.django_db


@pytest.fixture
def lenovo_computer():
    return Computer.objects.create(
        vendor='Lenovo',
        title='Lenovo IdeaPad 3 14 Laptop',
        striked_price=299.0,
        price=169.99
    )


@pytest.fixture
def apple_computer():
    return Computer.objects.create(
        vendor='Apple',
        title='2020 Apple M1 Macbook Pro 13',
        price=3000.0,
    )


@pytest.fixture
def api_client():
    return APIClient()


class TestSearchView:
    route = '/api/v1/search/'

    def test_lenovo(self, api_client, lenovo_computer, apple_computer):
        response = api_client.get(self.route, {'search_term': 'ideapa'})
        assert response.status_code == 200
        assert response.json()['results'][0]['id'] == lenovo_computer.id
        assert response.json()['count'] == 1

    def test_mac(self, api_client, lenovo_computer, apple_computer):
        response = api_client.get(self.route, {'search_term': 'apple'})
        assert response.status_code == 200
        assert response.json()['results'][0]['id'] == apple_computer.id
        assert response.json()['count'] == 1

    def test_all(self, api_client, lenovo_computer, apple_computer):
        response = api_client.get(self.route)
        assert response.status_code == 200
        assert response.json()['count'] == 2
