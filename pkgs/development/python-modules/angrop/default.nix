{
  lib,
  angr,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  setuptools,
  tqdm,
}:

buildPythonPackage rec {
  pname = "angrop";
  version = "9.2.11";
  pyproject = true;

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "angr";
    repo = "angrop";
    tag = "v${version}";
    hash = "sha256-wL6H4UqBqOHMQU91q0uJrgeS/wVvIbinpF9IBtli3Ig=";
  };

  build-system = [ setuptools ];

  dependencies = [
    angr
    tqdm
  ];

  # Tests have additional requirements, e.g., angr binaries
  # cle is executing the tests with the angr binaries already and is a requirement of angr
  doCheck = false;

  pythonImportsCheck = [ "angrop" ];

  meta = with lib; {
    description = "ROP gadget finder and chain builder";
    homepage = "https://github.com/angr/angrop";
    license = with licenses; [ bsd2 ];
    maintainers = with maintainers; [ fab ];
  };
}
