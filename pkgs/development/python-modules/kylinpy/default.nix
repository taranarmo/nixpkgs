{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  sqlalchemy,
}:

buildPythonPackage {
  pname = "kylinpy";
  version = "2.8.4";
  format = "pyproject";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/f2/b7/1828ab71898e671323cd76e8960cf1f5ea463a95c6fd63815a4d533cf1f8/kylinpy-2.8.4.tar.gz";
    hash = "sha256-QQasrA/IOrzY3qPB2eo8mt4Qis4GjeaivS4NdXGyZkM=";
  };

  doCheck = false;

  build-system = [ setuptools ];

  propagatedBuildInputs = [ sqlalchemy ];

  pythonImportsCheck = [ "kylinpy" ];

  meta = with lib; {
    description = "Apache Kylin Python Client Library";
    homepage = "https://github.com/Kyligence/kylinpy";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
