{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  certifi,
  charset-normalizer,
  dataclasses-json,
  idna,
  jsonpath-python,
  marshmallow,
  mypy-extensions,
  packaging,
  python-dateutil,
  requests,
  six,
  typing-inspect,
  typing-extensions,
  urllib3,
  setuptools,
}:

buildPythonPackage rec {
  pname = "airbyte-api";
  pyproject = true;
  build-system = [ setuptools ];
  version = "0.52.2";

  src = fetchFromGitHub {
    owner = "airbytehq";
    repo = "airbyte-api-python-sdk";
    rev = "v${version}";
    hash = "sha256-Tc3duGSgpjZq5MWrVVgZ7nJFfNy3u5+EZX9lGFf+UWk=";
  };

  dependencies = [
    certifi
    charset-normalizer
    dataclasses-json
    idna
    jsonpath-python
    marshmallow
    mypy-extensions
    packaging
    python-dateutil
    requests
    six
    typing-inspect
    typing-extensions
    urllib3
  ];

  pythonImportsCheck = [
    "airbyte_api"
  ];

  meta = with lib; {
    description = "Python Client SDK for Airbyte API";
    homepage = "https://github.com/airbytehq/airbyte-api-python-sdk";
    license = licenses.mit;
    maintainers = with maintainers; [ taranarmo ];
  };
}
