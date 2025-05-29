{ lib
, buildPythonPackage
, fetchTarball
, python3Packages
, pkgs
}:

buildPythonPackage rec {
  pname = "apache-airflow-core";
  version = "3.0.1";
  format = "pyproject";

  src = fetchTarball {
    url = "https://www.apache.org/dyn/closer.lua/airflow/${version}/apache-airflow-${version}-source.tar.gz";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # Placeholder, replace with actual hash
  };

  sourceRoot = "apache-airflow-${version}-source/airflow-core";

  nativeBuildInputs = [
    python3Packages.hatchling
    pkgs.pre-commit
    pkgs.nodejs-22_x
    pkgs.nodePackages.pnpm
    # pkgs.git # Optional, if needed for build steps beyond versioning
  ];

  propagatedBuildInputs = with python3Packages; [
    alembic # >=1.13.1,<2.0
    argcomplete # >=1.10
    attrs # >=23.1.0
    blinker # >=1.6.3
    click # >=8.1.3,<9
    connexion # >=3.0.5,<4 # with swagger-ui
    croniter # >=2.0.4,<2.1
    cryptography # >=42.0.5
    # pendulum # >=3.0.0 # (Python >=3.9)
    # pendulum # >=2.1.2,<3.0.0 # (Python <3.9) - Assuming Nixpkgs Python is >= 3.9
    (pendulum.override { python = python; }) # Let Nixpkgs handle the correct version
    flask # >=3.0.3,<4
    flask-appbuilder # >=4.4.1,<5.0.0
    flask-caching # >=2.2.0,<3
    flask-login # >=0.6.3,<0.7
    flask-session # >=0.5.0,<0.6
    flask-wtf # >=1.2.1,<2
    gunicorn # >=22.0.0,<23
    httpx # >=0.27.0
    itsdangerous # >=2.1.2
    jinja2 # >=3.1.3,<4
    jsonschema # >=4.21.1
    lazy-object-proxy # >=1.9.0
    linkify-it-py # >=2.0.2
    markdown # >=3.6,<4
    markdown-it-py # >=3.0.0,<4
    openapi-spec-validator # >=0.7.1,<0.8
    packaging # >=23.2
    pandas # >=2.2.0,<3
    psutil # >=5.9.8
    python-daemon # >=3.0.1,<4
    python-dateutil # >=2.9.0.post0,<3
    python-slugify # >=8.0.4,<9
    pyyaml # >=6.0.1,<7
    requests # >=2.31.0
    rich # >=13.7.1,<14
    setproctitle # >=1.3.3,<2
    sqlalchemy # >=2.0.27,<2.1
    sqlalchemy-jsonfield # >=1.0.0
    sqlalchemy-utils # >=0.41.1
    tabulate # >=0.9.0,<0.10
    tenacity # >=8.2.3,<9
    termcolor # >=2.4.0,<3
    typing-extensions # >=4.12.0,<5 # (Python <3.11)
    # typing-extensions is not needed for Python >= 3.11 as its features are part of the stdlib
    # However, Airflow lists it unconditionally. We'll include it, buildPythonPackage might filter it.
    tzlocal # >=5.2,<6
    uc-micro-py # >=1.0.6,<2
    werkzeug # >=3.0.3,<4
  ] ++ lib.optionals (python.pythonVersionMajor == 3 && python.pythonVersionMinor < 11) [
    typing-extensions # For <3.11
  ];

  # buildPythonPackage should handle the hatchling build process correctly.
  # hatch_build.py in airflow-core/ is expected to be triggered by hatchling
  # and compile UI assets.

  meta = with lib; {
    description = "Apache Airflow (core library)";
    homepage = "https://airflow.apache.org/";
    license = licenses.asl20;
    maintainers = with maintainers; [ ]; # Add maintainers
  };
}
