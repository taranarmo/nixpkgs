{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
  requests,
  aiohttp,
}:

buildPythonPackage rec {
  pname = "alibabacloud-tea";
  version = "1.0.2";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "tea-python";
    rev = "b7f130665ea41ddc1ad4116e3398950ddbf86706";
    sha256 = "sha256-lU606kNcu5EMGyEEJVDEPdrqViq4oqstb5NBHIFu/4Y=";
    fetchSubmodules = true;
  };

  pythonRemoveDeps = [ "alibabacloud-tea" ];

  dependencies = [
    requests
    aiohttp
  ];

  meta = with lib; {
    description = "Alibaba Cloud Tea Library for Python";
    homepage = "https://github.com/aliyun/tea-python";
    license = licenses.asl20;
    maintainers = with maintainers; [
      # your_github_handle
    ];
  };
}
