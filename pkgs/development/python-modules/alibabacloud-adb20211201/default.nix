{
  buildPythonPackage,
  fetchPypi,
  lib,
  setuptools,
}:

  buildPythonPackage rec {
  pname = "alibabacloud-adb20211201";
  version = "3.1.3";

  pyproject = true;
  build-system = [ setuptools ];

  src = fetchPypi {
    inherit pname version;
    hash = "";
  };

  # No dependencies listed in pyproject.toml for this package
  propagatedBuildInputs = [
    (fetchPypi {
      pname = "alibabacloud-tea-util";
      version = "0.3.13";
      hash = "sha256-pQV1uyzgQNs+whOuYSu6HjgqJ2837rvOM6dLApVbsms=";
    })
    (fetchPypi {
      pname = "alibabacloud_tea_openapi";
      version = "0.3.15";
      hash = "sha256-w/WzFPNeudnagD/Ut5MmwzcpV/AFJ27iIUyB50iniz0=";
    })
    (fetchPypi {
      pname = "alibabacloud-openapi-util";
      version = "0.2.2";
      hash = "sha256-uUqJjdpTA4MarCqm+GXIbRH0QfXGL4+IhqOMYvfOB+8=";
    })
    (fetchPypi {
      pname = "alibabacloud-endpoint-util";
      version = "0.0.4";
      hash = "sha256-lyisIvhnb/thXEi6tlmP+o29kjqvIcnIYHqyAUWeS1U=";
    })
  ];

  # No tests available
  doCheck = false;

  meta = with lib; {
    description = "Alibaba Cloud adb (20211201) SDK Library for Python";
    homepage = "https://github.com/aliyun/alibabacloud-python-sdk";
    license = licenses.asl20;
    maintainers = with maintainers; [
      # your_github_handle
    ];
  };
}
