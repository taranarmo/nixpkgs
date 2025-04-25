{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  # build system dependencies
  hatchling,
  setuptools,
  # runtime dependencies
  sniffio,
  typing-extensions,
  wrapt,
  # test dependencies
  pytest,
  pytest-asyncio,
}:

buildPythonPackage rec {
  pname = "aiologic";
  version = "0.14.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "x42005e1f";
    repo = pname;
    tag = "${version}";
    hash = "sha256-XhkclQth3RpoBan7OS/0CsCpdqaCvoyiDskxH3rA9DI=";
  };

  build-system = [
    hatchling
    setuptools
  ];

  dependencies = [
    sniffio
    wrapt
  ]
  ++ lib.optionals (pythonOlder "3.13") [
    typing-extensions
  ];

  checkInputs = [
    pytest
    pytest-asyncio
  ];

  pythonImportsCheck = [ "aiologic" ];

  meta = with lib; {
    description = "GIL-powered* locking library for Python";
    homepage = "https://github.com/x42005e1f/aiologic";
    license = licenses.mit;
    maintainers = [ taranarmo ];
  };
}
