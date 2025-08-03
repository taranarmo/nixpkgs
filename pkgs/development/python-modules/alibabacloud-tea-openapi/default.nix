{
  buildPythonPackage,
  fetchPypi,
  lib,
  setuptools,
  pkgs,
}:

buildPythonPackage rec {
  pname = "alibabacloud_tea_openapi";
  version = "0.3.15";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-VqCqbVHYzxjAzz0hnYYfRpf1nT4X+mcmsRAYJtk5iKI=";
  };

  propagatedBuildInputs = [
    pkgs.python3Packages.alibabacloud-tea-util
    pkgs.python3Packages.alibabacloud-credentials
    pkgs.python3Packages.alibabacloud-openapi-util
    pkgs.python3Packages.alibabacloud-gateway-spi
    pkgs.python3Packages.alibabacloud-tea-xml
  ];

  # No tests available
  doCheck = false;

  meta = with lib; {
    description = "Alibaba Cloud Tea OpenAPI Library for Python";
    homepage = "https://github.com/aliyun/alibabacloud-tea-openapi";
    license = licenses.asl20;
    maintainers = with maintainers; [
      # your_github_handle
    ];
  };
}
