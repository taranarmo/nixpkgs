{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  alibabacloud-tea,
  alibabacloud-credentials-api,
  apscheduler,
  aiofiles,
  tzlocal,
}:

buildPythonPackage rec {
  pname = "alibabacloud-credentials";
  version = "0.2.4"; # Assuming latest version, will verify from setup.py

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "credentials-python";
    rev = "3166ffcb032882910d6cee71a2ba138b9e3b3abd";
    sha256 = "sha256-5WoH4YJeVIESy7ZhdosoEQiW0InDmoCGH4bMeYtO4rg=";
    fetchSubmodules = true;
  };

  pythonRemoveDeps = [ "alibabacloud-tea" ];
  propagatedBuildInputs = [
    alibabacloud-tea
    alibabacloud-credentials-api
    apscheduler
    aiofiles
    tzlocal
  ];

  # No tests available
  doCheck = false;

  meta = with lib; {
    description = "Alibaba Cloud Credentials Library for Python";
    homepage = "https://github.com/aliyun/credentials-python";
    license = licenses.asl20;
    maintainers = with maintainers; [
      # your_github_handle
    ];
  };
}
