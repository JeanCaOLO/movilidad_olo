import pytest

from application.use_cases import movilidad as mov
from application.use_cases.movilidad import (
    DeleteMovilidadEntryUseCase,
    GetMovilidadEntryUseCase,
    ListMovilidadEntriesUseCase,
    SaveMovilidadEntryUseCase,
)
from domain.exceptions import NotFoundError, ValidationError
from fakes.fake_app_unit_of_work import FakeAppUnitOfWork


def _seed(uow: FakeAppUnitOfWork) -> None:
    uow.entries.rows.update(
        {
            "colaborador:a": {"id": "a", "nombre": "Ana"},
            "colaborador:b": {"id": "b", "pais": "VE"},
            "evaluacion:1": {"id": "1", "colaboradorId": "b"},
            "directorio": {"jefes": {}, "correos": {}},
            "config": {"closedPeriods": []},
        }
    )


def test_lists_keys_by_prefix_like_the_original_store():
    uow = FakeAppUnitOfWork()
    _seed(uow)
    listing = ListMovilidadEntriesUseCase(uow.factory)
    assert listing.execute("colaborador:", include_values=False) == {
        "keys": ["colaborador:a", "colaborador:b"]
    }
    assert listing.execute("nada:", include_values=False) == {"keys": []}


def test_every_country_is_readable_and_writable_as_in_the_effective_policies():
    uow = FakeAppUnitOfWork()
    _seed(uow)
    SaveMovilidadEntryUseCase(uow.factory).execute("colaborador:a", {"value": {"id": "a", "pais": "VE"}})
    SaveMovilidadEntryUseCase(uow.factory).execute("colaborador:z", {"value": {"id": "z"}})
    assert uow.entries.rows["colaborador:a"] == {"id": "a", "pais": "VE"}
    assert GetMovilidadEntryUseCase(uow.factory).execute("colaborador:z").value == {"id": "z"}
    DeleteMovilidadEntryUseCase(uow.factory).execute("colaborador:b")
    DeleteMovilidadEntryUseCase(uow.factory).execute("colaborador:no-existe")
    assert "colaborador:b" not in uow.entries.rows
    assert uow.commits == 4


def test_list_with_values_paginates_by_cursor_and_byte_budget(monkeypatch):
    uow = FakeAppUnitOfWork()
    for i in range(5):
        uow.entries.rows[f"historico:{i}"] = {"id": str(i), "foto": "x" * 100}
    listing = ListMovilidadEntriesUseCase(uow.factory)
    page = listing.execute("historico:", include_values=True, limit=2)
    assert [e.key for e in page["items"]] == ["historico:0", "historico:1"]
    assert page["next_cursor"] == "historico:1"
    rest = listing.execute("historico:", include_values=True, cursor=page["next_cursor"])
    assert [e.key for e in rest["items"]] == ["historico:2", "historico:3", "historico:4"]
    assert rest["next_cursor"] is None
    monkeypatch.setattr(mov, "PAGE_BYTE_BUDGET", 250)
    budget = listing.execute("historico:", include_values=True)
    assert len(budget["items"]) == 2 and budget["next_cursor"] == "historico:1"
    assert budget["items"][0].to_dict() == {"key": "historico:0", "value": {"id": "0", "foto": "x" * 100}}


def test_first_row_is_returned_even_if_larger_than_the_budget(monkeypatch):
    uow = FakeAppUnitOfWork()
    uow.entries.rows["colaborador:grande"] = {"foto": "x" * 1000}
    monkeypatch.setattr(mov, "PAGE_BYTE_BUDGET", 10)
    page = ListMovilidadEntriesUseCase(uow.factory).execute("colaborador:", include_values=True)
    assert [e.key for e in page["items"]] == ["colaborador:grande"] and page["next_cursor"] is None


def test_validations_missing_rows_and_encoded_keys():
    uow = FakeAppUnitOfWork()
    _seed(uow)
    get = GetMovilidadEntryUseCase(uow.factory)
    assert get.execute("colaborador%3Aa").key == "colaborador:a"
    with pytest.raises(NotFoundError):
        get.execute("colaborador:missing")
    with pytest.raises(ValidationError):
        get.execute("  ")
    with pytest.raises(ValidationError):
        SaveMovilidadEntryUseCase(uow.factory).execute("config", {})
    with pytest.raises(ValidationError):
        ListMovilidadEntriesUseCase(uow.factory).execute("x", include_values=True, limit=0)
    with pytest.raises(ValidationError):
        ListMovilidadEntriesUseCase(uow.factory).execute("x" * 1001, include_values=False)
