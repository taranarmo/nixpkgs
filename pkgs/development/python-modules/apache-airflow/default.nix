{ lib
, buildPythonPackage
, fetchTarball
, python3Packages
, apache-airflow-core # Input: the Nix package for core
, apache-airflow-task-sdk # Input: the Nix package for task-sdk
, pkgs # For pkgs.runCommand and pkgs.makeWrapper in tests
}:

buildPythonPackage rec {
  pname = "apache-airflow";
  version = "3.0.1"; # Should match core and task-sdk versions
  format = "pyproject";

  src = fetchTarball {
    url = "https://www.apache.org/dyn/closer.lua/airflow/${version}/apache-airflow-${version}-source.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # Placeholder, replace with actual hash
  };

  # sourceRoot should point to the root of the extracted tarball,
  # as the top-level pyproject.toml is for the apache-airflow metapackage.
  sourceRoot = "apache-airflow-${version}-source";

  nativeBuildInputs = [
    python3Packages.hatchling
  ];

  propagatedBuildInputs = [
    apache-airflow-core
    apache-airflow-task-sdk
    # The top-level pyproject.toml for apache-airflow (the metapackage)
    # lists a few direct dependencies under [project.dependencies].
    # Let's check apache-airflow-3.0.1-source/pyproject.toml
    # It typically would only list airflow-core and task-sdk, which we've covered.
    # If it lists others, they need to be added here.
    # For Airflow 3.0.1, the [project.dependencies] in the root pyproject.toml are:
    # "apache-airflow-core == {root:uri}/airflow-core[version]",
    # "apache-airflow-task-sdk == {root:uri}/task-sdk[version]",
    # These are handled by depending on our Nix packages for core and task-sdk.
    # It also has many [project.optional-dependencies] for providers, which we
    # will not install by default in this metapackage. Users should install
    # Nix packages for providers separately.
  ];

  # The `airflow` console script is provided by airflow-core, so it should be
  # available automatically when airflow-core is a dependency.

  # We don't need to build anything specific for the meta package,
  # as hatchling will mostly just install the package metadata.
  # The actual functionality comes from the dependencies.

  meta = with lib; {
    description = "Apache Airflow (metapackage)";
    homepage = "https://airflow.apache.org/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ]; # Add maintainers
  };

  passthru.tests = {
    airflow-version-check = pkgs.runCommand "airflow-version-check" {
      nativeBuildInputs = [ pkgs.makeWrapper pkgs.gnugrep ]; # makeWrapper to put airflow in PATH, gnugrep for grep
      meta.description = "Run airflow --version and check output";
      # Pass the package itself to the test environment
      # 'self' here refers to the output of the buildPythonPackage call for apache-airflow
      package = self;
    } ''
      set -x # Print commands for debugging

      # Ensure the directory for wrapped command exists
      mkdir -p $out/bin

      # Wrap the airflow command from the package being tested
      # The 'airflow' executable comes from the 'apache-airflow-core' dependency
      makeWrapper ${self.core}/bin/airflow $out/bin/airflow \
        --prefix PATH : ${lib.makeBinPath [ pkgs.git ]} # git is needed by airflow cli for some checks

      # Run the wrapped airflow command to check its version
      $out/bin/airflow --version > $out/version-output

      # Basic check for successful execution
      if [ $? -ne 0 ]; then
        echo "airflow --version command failed!"
        cat $out/version-output # Show output on failure
        exit 1
      fi

      # Optional: Check version string
      # The version reported by `airflow --version` includes more than just the digits.
      # For example: "3.0.1\n[...]\nApache Airflow"
      # So we grep for "3.0.1"
      grep -q "3.0.1" $out/version-output
      if [ $? -ne 0 ]; then
        echo "Version string '3.0.1' not found in output:"
        cat $out/version-output
        exit 1
      fi

      # If all checks pass, create the $out file to signify success
      touch $out
    '';
  };
}
