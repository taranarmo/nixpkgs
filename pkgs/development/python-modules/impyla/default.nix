{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  six,
  bitarray,
  thrift,
  thrift-sasl,
}:

buildPythonPackage rec {
  pname = "impyla";
  version = "0.22.0";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "cloudera";
    repo = "impyla";
    rev = "v${version}";
    hash = "sha256-84jchE2No2CY0v15iQgyDfekIuVBcsnF4t8kH3FCvqM=";
  };

  doCheck = false; # tests require Impala instance

  pythonRelaxDeps = [ "thrift" ];

  build-system = [ setuptools ];

  propagatedBuildInputs = [
    six
    bitarray
    thrift
    thrift-sasl
  ];

  pythonImportsCheck = [ "impala" ];

  meta = with lib; {
    description = "Python client for the Impala distributed query engine";
    homepage = "https://github.com/cloudera/impyla";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
