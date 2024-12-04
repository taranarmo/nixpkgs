{ lib
, stdenv
, python
, buildPythonPackage
, fetchFromGitHub
, alembic
, argcomplete
, asgiref
, attrs
, blinker
, cached-property
, cattrs
, clickclick
, colorlog
, configupdater
, connexion
, cron-descriptor
, croniter
, cryptography
, deprecated
, dill
#, flask
#, flask-login
#, flask-caching
#, flask-session
#, flask-wtf
, gitpython
, google-re2
, graphviz
, gunicorn
, hatchling
, hatch-requirements-txt
, hatch-fancy-pypi-readme
, httpx
, iso8601
, importlib-resources
, importlib-metadata
, inflection
, itsdangerous
, jinja2
, jsonschema
, lazy-object-proxy
, linkify-it-py
, lockfile
, markdown
, markupsafe
, marshmallow-oneofschema
, mdit-py-plugins
, numpy
, openapi-spec-validator
, opentelemetry-api
, opentelemetry-exporter-otlp
, pandas
, pathspec
, pendulum
, psutil
, pydantic
, pygments
, pyjwt
, pytest-httpbin
, python-daemon
, python-dateutil
, python-nvd3
, python-slugify
, python3-openid
, pythonOlder
, pyyaml
, rich
, rich-argparse
, setproctitle
, sqlalchemy
, sqlalchemy-jsonfield
, swagger-ui-bundle
, tabulate
, tenacity
, termcolor
, typing-extensions
, unicodecsv
, werkzeug
, freezegun
, pytest-asyncio
, pytestCheckHook
, time-machine
, mkYarnPackage
, fetchYarnDeps
, writeScript

# Extra airflow providers to enable
, enabledProviders ? []
}:
let
  version = "2.10.3";

  airflow-src = fetchFromGitHub rec {
    owner = "apache";
    repo = "airflow";
    rev = "refs/tags/${version}";
    # Download using the git protocol rather than using tarballs, because the
    # GitHub archive tarballs don't appear to include tests
    forceFetchGit = true;
    hash = "sha256-R+VsaVnZvgOP+cZUUwaZxrlLqwbabJ882D6o0y5N5vQ=";
  };
in
buildPythonPackage rec {
  pname = "apache-airflow";
  inherit version;
  src = airflow-src;

  pyproject = true;
  build-system = [
    hatchling
  ];

  disabled = pythonOlder "3.8";

  propagatedBuildInputs = [
    alembic
    argcomplete
    asgiref
    attrs
    blinker
    cached-property
    cattrs
    clickclick
    colorlog
    configupdater
    connexion
    cron-descriptor
    croniter
    cryptography
    deprecated
    dill
    #flask
    #flask-caching
    #flask-session
    #flask-wtf
    #flask-login
    gitpython
    google-re2
    graphviz
    gunicorn
    httpx
    iso8601
    importlib-resources
    inflection
    itsdangerous
    jinja2
    jsonschema
    lazy-object-proxy
    linkify-it-py
    lockfile
    markdown
    markupsafe
    marshmallow-oneofschema
    mdit-py-plugins
    numpy
    openapi-spec-validator
    opentelemetry-api
    opentelemetry-exporter-otlp
    pandas
    pathspec
    pendulum
    psutil
    pydantic
    pygments
    pyjwt
    pytest-httpbin
    python-daemon
    python-dateutil
    python-nvd3
    python-slugify
    python3-openid
    pyyaml
    rich
    rich-argparse
    setproctitle
    sqlalchemy
    sqlalchemy-jsonfield
    swagger-ui-bundle
    tabulate
    tenacity
    termcolor
    typing-extensions
    unicodecsv
    werkzeug
  ] ++ lib.optionals (pythonOlder "3.9") [
    importlib-metadata
  ];

  nativeCheckInputs = [
    freezegun
    pytest-asyncio
    pytestCheckHook
    time-machine
  ];

  # By default, source code of providers is included but unusable due to missing
  # transitive dependencies. To enable a provider, add it to extraProviders
  # above
  INSTALL_PROVIDERS_FROM_SOURCES = "true";

  pythonRelaxDeps = [
    "colorlog"
    "opentelemetry-api"
    "pathspec"
  ];

  # allow for gunicorn processes to have access to Python packages
  makeWrapperArgs = [
    "--prefix PYTHONPATH : $PYTHONPATH"
  ];

  postInstall = ''
    # Needed for pythonImportsCheck below
    export HOME=$(mktemp -d)
  '';

  pythonImportsCheck = [
    "airflow"
  ];

  preCheck = ''
    export AIRFLOW_HOME=$HOME
    export AIRFLOW__CORE__UNIT_TEST_MODE=True
    export AIRFLOW_DB="$HOME/airflow.db"
    export PATH=$PATH:$out/bin

    airflow version
    airflow db init
    airflow db reset -y
  '';

  pytestFlagsArray = [
    "tests/core/test_core.py"
  ];

  disabledTests = lib.optionals stdenv.hostPlatform.isDarwin [
    "bash_operator_kill" # psutil.AccessDenied
  ];

  meta = with lib; {
    description = "Programmatically author, schedule and monitor data pipelines";
    homepage = "https://airflow.apache.org/";
    license = licenses.asl20;
    maintainers = with maintainers; [ bhipple gbpdt ingenieroariel ];
  };
}
