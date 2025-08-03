{
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  alibabacloud-tea-util,
  cryptography,
}:

buildPythonPackage rec {
  pname = "alibabacloud-openapi-util";
  version = "0.2.3"; # Assuming latest version, will verify from setup.py

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "darabonba-openapi-util";
    rev = "d20cca0cef4da79fe68a0f21dc46ea5c60526622";
    sha256 = "sha256-K8xQtmEfQs+fA0lSGR5m1nonY8Ky7SubLknT9GWVAMI=";
    fetchSubmodules = true;
  };

  sourceRoot = "${src.name}/python";
  pyproject = true;
  build-system = [ setuptools ];

  propagatedBuildInputs = [
    alibabacloud-tea-util
    cryptography
  ];

}
