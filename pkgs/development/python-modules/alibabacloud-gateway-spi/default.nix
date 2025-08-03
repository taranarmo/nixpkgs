{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  alibabacloud-credentials,
}:

buildPythonPackage rec {
  pname = "alibabacloud-gateway-spi";
  version = "0.1.0";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "alibabacloud-gateway";
    rev = "b612af68d7484d5ddc0cc9b06c0441744fbad03d";
    sha256 = "sha256-RLs4KnljuUlfb/++TZ0SEOC4xdwuLnsKq9p/5vocVUc=";
    fetchSubmodules = true;
  };

  pythonRemoveDeps = [ "alibabacloud-credentials" ];
  propagatedBuildInputs = [ alibabacloud-credentials ];

  sourceRoot = "${src.name}/${pname}/python";
}
