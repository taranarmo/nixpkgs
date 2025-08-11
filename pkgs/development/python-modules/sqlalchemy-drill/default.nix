{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  requests,
  ijson,
  sqlalchemy,
}:

buildPythonPackage rec {
  pname = "sqlalchemy-drill";
  format = "pyproject";
  version = "1.1.9";

  src = fetchFromGitHub {
    owner = "JohnOmernik";
    repo = "sqlalchemy-drill";
    rev = "v${version}";
    hash = "sha256-Srs5vzaJ73uOaIq0sfLDd2zgKPa4uuW0jHQddLPo594=";
  };

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    requests
    ijson
    sqlalchemy
  ];

  doChecks = false; # tests require a running Drill instance

  pythonImportsCheck = [ "sqlalchemy_drill" ];

  meta = with lib; {
    description = "Apache Drill for SQLAlchemy";
    homepage = "https://github.com/JohnOmernik/sqlalchemy-drill";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
