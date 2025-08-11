{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  thrift,
  pure-sasl,
  six,
}:

buildPythonPackage rec {
  pname = "thrift-sasl";
  version = "0.4.3";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "cloudera";
    repo = "thrift_sasl";
    rev = "v${version}";
    hash = "sha256-6eZJEZsjjYPXKDv+xOT8mu57Kw8t/zzW/2EjYJsPTCE=";
  };

  doCheck = false;

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    thrift
    pure-sasl
    six
  ];

  pythonImportsCheck = [ "thrift_sasl" ];

  meta = with lib; {
    description = "Thrift SASL Python module that implements SASL transports for Thrift";
    homepage = "https://github.com/cloudera/thrift_sasl";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
