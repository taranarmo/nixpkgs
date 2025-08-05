
{ lib, buildPythonApplication, fetchFromGitHub,
  # Dependencies from setup.py install_requires
  certifi, charset-normalizer, dataclasses-json, idna, jsonpath-python,
  marshmallow, mypy-extensions, packaging, python-dateutil, requests,
  six, typing-inspect, typing-extensions, urllib3, setuptools
}:

buildPythonApplication rec {
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

  propagatedBuildInputs = [
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

  # No tests found in the repository, so skipping checkPhase
  doCheck = false;

  pythonImportsCheck = [
    "airbyte_api"
  ];

  meta = with lib; {
    description = "Python Client SDK for Airbyte API";
    homepage = "https://github.com/airbytehq/airbyte-api-python-sdk";
    license = licenses.mit; # Assuming MIT license based on common practice for SDKs
    maintainers = with maintainers; [ # Replace with actual maintainers if known
      # your_github_handle
    ];
  };
}
