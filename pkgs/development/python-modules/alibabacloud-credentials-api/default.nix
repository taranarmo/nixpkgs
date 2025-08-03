{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
}:

buildPythonPackage rec {
  pname = "alibabacloud-credentials-api";
  version = "1.0.0";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "alibabacloud-credentials-api";
    rev = "93db397fb8cdbade925af9302508d35e63096a49";
    sha256 = "sha256-ns2ekI6V20vzzvKit1WEoLa52gmqQahumHiopFXdndI=";
    fetchSubmodules = true;
  };

  sourceRoot = "${src.name}/python";

  # No dependencies listed in pyproject.toml for this package
  propagatedBuildInputs = [
  ];


  meta = with lib; {
    description = "Alibaba Cloud Credentials API Library for Python";
    homepage = "https://github.com/aliyun/alibabacloud-credentials-api";
    license = licenses.asl20;
    maintainers = with maintainers; [
      # your_github_handle
    ];
  };
}
