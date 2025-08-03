{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  alibabacloud-tea,
}:

buildPythonPackage rec {
  pname = "alibabacloud-tea-util";
  version = "0.3.13"; # Assuming latest version, will verify from setup.py

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "tea-util";
    rev = "8acc9b093adf2f17d41d66826487c713c6ae0865";
    sha256 = "sha256-xvieSU/3Yd2k8u7wfLL3yBoFePIShtfuSkjh+y8LZNA=";
    fetchSubmodules = true;
  };

  sourceRoot = "${src.name}/python";

  pythonRemoveDeps = [ "alibabacloud-tea" ];
  propagatedBuildInputs = [ alibabacloud-tea ];

  meta = with lib; {
    description = "Alibaba Cloud Tea Util Library for Python";
    homepage = "https://github.com/aliyun/tea-util";
    license = licenses.asl20;
    maintainers = with maintainers; [
      # your_github_handle
    ];
  };
}
