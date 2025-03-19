{
  lib,
  stdenv,
  python,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  gitpython,
  gitdb,
  packaging,
  pathspec,
  pluggy,
  smmap,
  tomli,
  trove-classifiers,
  sqlalchemy-utils,
  fastapi,
  libcst,
  a2wsgi,
  uuid6,
  cadwyn,
  svcs,
  flit-core,
  writeScript,
  msgspec,
  retryhttp,
  structlog,

  setproctitle,
  pygments,
  pendulum,
  pandas,
  uvicorn,

  alembic,
  argcomplete,
  asgiref,
  attrs,
  blinker,
  colorlog,
  configupdater,
  connexion,
  cron-descriptor,
  croniter,
  cryptography,
  deprecated,
  dill,
  flask,
  flask-caching,
  flask-session,
  flask-wtf,
  fsspec,
  google-re2,
  gunicorn,
  httpx,
  itsdangerous,
  jinja2,
  jsonschema,
  lazy-object-proxy,
  linkify-it-py,
  lockfile,
  markdown-it-py,
  markupsafe,
  marshmallow-oneofschema,
  mdit-py-plugins,
  methodtools,
  opentelemetry-api,
  opentelemetry-exporter-otlp,
  psutil,
  pyjwt,
  python-daemon,
  python-dateutil,
  python-nvd3,
  python-slugify,
  requests,
  requests-toolbelt,
  rfc3339-validator,
  rich,
  rich-argparse,
  sqlalchemy,
  sqlalchemy-jsonfield,
  tabulate,
  tenacity,
  termcolor,
  universal-pathlib,
  werkzeug,

  enabledProviders ? [
    "common_compat"
    "common_io"
    "common_sql"
    "fab"
    "smtp"
    "sqlite"
    "standard"
  ],
}:
let
  version = "3.0.0rc2";

  airflow-src = fetchFromGitHub {
    owner = "apache";
    repo = "airflow";
    tag = "${version}";
    forceFetchGit = true;
    hash = "sha256-OQfcqXMrKf+HM74MaYqiIxoM7So9tgw0+V7v2TR/m/Y=";
  };

  providers = import ./providers.nix;
  providerMapping = {
    common_compat = "common/compat";
    common_io = "common/io";
    common_sql = "common/sql";
  };
  getProviderPath = provider: if lib.hasAttr provider providerMapping then providerMapping.${provider} else provider;
  getProviderDeps = provider: map (dep: python.pkgs.${dep}) providers.${provider}.deps;
  getProviderImports = provider: providers.${provider}.imports;
  providerImports = lib.concatMap getProviderImports enabledProviders;

  getProviderVersion = provider: let
    pyproject = builtins.fromTOML (builtins.readFile "${airflow-src}/providers/${getProviderPath provider}/pyproject.toml");
  in pyproject.project.version;

  buildProvider = provider: buildPythonPackage {
    pname = "apache-airflow-providers-${provider}";
    version = getProviderVersion provider;
    src = "${airflow-src}/providers/${getProviderPath provider}";
    buildInputs = [ flit-core ];
    dependencies = getProviderDeps provider;
    pythonRemoveDeps = [
      "apache-airflow"
    ];
    pythonRelaxDeps = [
      "flit-core"
    ];
    pyproject = true;
  };

  providerPackages = map buildProvider enabledProviders;

  taskSdk = buildPythonPackage {
    pname = "task-sdk";
    version = "1.0.0"; # Replace with the actual version if needed
    src = "${airflow-src}/task-sdk";
    build-system = [ hatchling attrs ];
    dependencies = [
      httpx
      jinja2
      methodtools
      msgspec
      pendulum
      psutil
      python-dateutil
      retryhttp
      structlog
    ];
    pyproject = true;
  };

in
buildPythonPackage {
  pname = "apache-airflow";
  inherit version;
  src = airflow-src;
  pyproject = true;
  build-system = [ hatchling ];

  dependencies = [
    cadwyn
    svcs
    taskSdk
    pandas
    uvicorn
  ] ++ providerPackages;

  propagatedBuildInputs =
    [
      gitpython
      gitdb
      packaging
      pathspec
      pluggy
      smmap
      tomli
      trove-classifiers
      sqlalchemy-utils
      fastapi
      libcst
      a2wsgi
      uuid6
      alembic
      argcomplete
      asgiref
      attrs
      blinker
      colorlog
      configupdater
      connexion
      cron-descriptor
      croniter
      cryptography
      deprecated
      dill
      flask-caching
      flask-session
      flask-wtf
      flask
      fsspec
      google-re2
      gunicorn
      httpx
      itsdangerous
      jinja2
      jsonschema
      lazy-object-proxy
      linkify-it-py
      lockfile
      markdown-it-py
      markupsafe
      marshmallow-oneofschema
      mdit-py-plugins
      methodtools
      opentelemetry-api
      opentelemetry-exporter-otlp
      pendulum
      psutil
      pygments
      pyjwt
      python-daemon
      python-dateutil
      python-nvd3
      python-slugify
      requests
      requests-toolbelt
      rfc3339-validator
      rich-argparse
      rich
      setproctitle
      sqlalchemy
      sqlalchemy-jsonfield
      tabulate
      tenacity
      termcolor
      universal-pathlib
      werkzeug
    ];

  pythonRelaxDeps = [
    "colorlog"
    "flask-appbuilder"
    "opentelemetry-api"
    "pathspec"
  ];

  makeWrapperArgs = [
    "--prefix PYTHONPATH : $PYTHONPATH"
  ];

  pythonImportsCheck = [
    "airflow"
  ] ++ providerImports;

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

  passthru.updateScript = writeScript "update.sh" ''
    #!/usr/bin/env nix-shell
    ./update-providers.py
  '';

  meta = with lib; {
    description = "Programmatically author, schedule and monitor data pipelines";
    homepage = "https://airflow.apache.org/";
    license = licenses.asl20;
    maintainers = with maintainers; [
      bhipple
      gbpdt
      ingenieroariel
    ];
  };
}
