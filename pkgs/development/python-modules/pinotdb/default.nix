{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  ciso8601,
  httpx,
  requests,
  h11,
}:

buildPythonPackage rec {
  pname = "pinotdb";
  version = "5.7.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "python-pinot-dbapi";
    repo = "pinot-dbapi";
    rev = "release-${version}";
    hash = "sha256-d/UuqjSa7p7pJU4cd5w6K4OJoeSYBCx8QrAD01qaL1U=";
  };

  doCheck = false;

  buildInputs = [ poetry-core ];

  propagatedBuildInputs = [
    ciso8601
    httpx
    requests
    h11
  ];

  pythonImportsCheck = [ "pinotdb" ];

  meta = with lib; {
    description = "Python DB-API and SQLAlchemy dialect for Pinot.";
    homepage = "https://github.com/python-pinot-dbapi/pinot-dbapi";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
