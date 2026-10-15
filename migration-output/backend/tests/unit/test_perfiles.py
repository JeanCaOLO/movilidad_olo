from uuid import uuid4

import pytest

from application.dto.principal import Principal
from application.use_cases.perfiles import GetMyCountryProfileUseCase
from application.use_cases.resolve_current_user import ResolveCurrentUserUseCase
from domain.entities.country_profile import CountryProfile
from domain.exceptions import UnauthorizedError
from fakes.fake_app_unit_of_work import FakeAppUnitOfWork


def test_returns_own_profile_with_original_shape():
    uow = FakeAppUnitOfWork()
    user_id = uuid4()
    uow.profiles.rows[user_id] = CountryProfile(pais="VE", es_admin=False, email="z@ologistics.com")
    uow.profiles.rows[uuid4()] = CountryProfile(pais="CR", es_admin=False, email="otro@ologistics.com")
    profile = GetMyCountryProfileUseCase(uow.factory).execute(Principal(subject="s", user_id=user_id))
    assert profile.to_dict() == {"pais": "VE", "es_admin": False, "email": "z@ologistics.com"}


def test_missing_profile_returns_none_and_requires_app_user():
    uow = FakeAppUnitOfWork()
    use_case = GetMyCountryProfileUseCase(uow.factory)
    assert use_case.execute(Principal(subject="s", user_id=uuid4())) is None
    with pytest.raises(UnauthorizedError):
        use_case.execute(Principal(subject="s"))


def test_migrated_admin_is_linked_by_verified_email_keeping_original_id():
    uow = FakeAppUnitOfWork()
    original_id = uuid4()
    uow.app_users.add_migrated(original_id, "lamador@ologistics.com")
    resolve = ResolveCurrentUserUseCase(lambda: uow)
    principal = Principal(
        subject="cognito-sub", email="lamador@ologistics.com", claims={"email_verified": "true"}
    )
    assert resolve.execute(principal).user_id == original_id
