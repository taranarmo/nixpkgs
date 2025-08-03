{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  alibabacloud-tea,
}:

buildPythonPackage rec {
  pname = "alibabacloud-tea-xml";
  version = "0.1.0";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "tea-xml";
    rev = "549d00682dbe274dafdee960bfd1b046ee376289";
    sha256 = "sha256-2oyYynl59uI+k7OIm8FUtcI3g6Td2Lo4bJqBMd3FB4g=";
    fetchSubmodules = true;
  };

  sourceRoot = "${src.name}/python";

  pythonRemoveDeps = [ "alibabacloud-tea" ];

  propagatedBuildInputs = [
    alibabacloud-tea
  ];
}
