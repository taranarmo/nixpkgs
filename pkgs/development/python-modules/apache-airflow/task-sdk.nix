{ lib
, buildPythonPackage
, fetchTarball
, python3Packages
, apache-airflow-core # This will be the Nix attribute for the core package
}:

buildPythonPackage rec {
  pname = "apache-airflow-task-sdk";
  version = "3.0.1"; # Should match the core version
  format = "pyproject";

  src = fetchTarball {
    url = "https://www.apache.org/dyn/closer.lua/airflow/${version}/apache-airflow-${version}-source.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # Placeholder, replace with actual hash
  };

  sourceRoot = "apache-airflow-${version}-source/task-sdk";

  nativeBuildInputs = [
    python3Packages.hatchling
  ];

  propagatedBuildInputs = [
    apache-airflow-core # Dependency on the core package
    # Add other dependencies from task-sdk/pyproject.toml if any
    # Based on Airflow 3.0.1 task-sdk/pyproject.toml, it only has:
    # "apache-airflow-core == {root:parentdir}/airflow-core[version]", which is handled by the above.
    # And dev dependencies which are not included here.
  ];

  # Assuming no special build steps are needed for the task-sdk beyond what hatchling handles.

  meta = with lib; {
    description = "Apache Airflow (task SDK library)";
    homepage = "https://airflow.apache.org/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ]; # Add maintainers
  };
}
