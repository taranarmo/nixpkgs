{
  lib,
  stdenv,
  python,
  buildPythonPackage,
  buildPythonApplication,
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
  writableTmpDirAsHomeHook,
  msgspec,
  retryhttp,
  structlog,

  setproctitle,
  pygments,
  pendulum,
  pandas,
  uvicorn,

  aiosqlite,
  pydantic,
  aiologic,
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

  enabledProviders ? [ ],
}:
let
  version = "3.0.3";

  airflow-src = fetchFromGitHub {
    owner = "apache";
    repo = "airflow";
    tag = "${version}";
    forceFetchGit = true;
    hash = "sha256-/YZe9vKG3VJy2SzhSMl9SGspimcrmhT1yxAWMhvGYWg=";
  };

  requiredProviders = [
    "common_compat"
    "common_io"
    "common_sql"
    "smtp"
    "sqlite"
    "standard"
  ];

  providers = import ./providers.nix;
  getProviderPath = provider: lib.replaceStrings [ "_" ] [ "/" ] provider;
  getProviderDeps = provider: map (dep: python.pkgs.${dep}) providers.${provider}.deps;
  getProviderImports = provider: providers.${provider}.imports;
  providerImports = lib.concatMap getProviderImports enabledProviders;

  getProviderVersion =
    provider:
    let
      pyproject = builtins.fromTOML (
        builtins.readFile "${airflow-src}/providers/${getProviderPath provider}/pyproject.toml"
      );
    in
    pyproject.project.version;

  buildProvider =
    provider:
    buildPythonPackage {
      pname = "apache-airflow-providers-${provider}";
      version = getProviderVersion provider;
      src = "${airflow-src}/providers/${getProviderPath provider}";
      buildInputs = [ flit-core ];
      pyproject = true;
      dependencies = getProviderDeps provider;
      pythonRemoveDeps = [
        "apache-airflow"
      ];
      pythonRelaxDeps = [
        "flit-core"
      ];
    };

  providerPackages = map buildProvider (enabledProviders ++ requiredProviders);

  airflowCore = buildPythonPackage {
    pname = "apache-airflow-core";
    inherit version;
    src = airflow-src;
    preBuild = "cd airflow-core";
    build-system = [ hatchling ];
    pyproject = true;

    doCheck = false;

    postPatch = ''
      # airflow-core use different trove-classifiers version from other components
      substituteInPlace airflow-core/pyproject.toml \
        --replace-fail 'trove-classifiers==2025.4.11.15' 'trove-classifiers==2025.5.9.12'
      # remove cyclic dep
      substituteInPlace airflow-core/pyproject.toml \
        --replace-fail '"apache-airflow-task-sdk<1.1.0,>=1.0.3",' ' '
    '';

    dependencies = [
      gitpython
      pluggy
      gitdb
      smmap
      marshmallow-oneofschema
      methodtools
      opentelemetry-api
      opentelemetry-exporter-otlp
      pendulum
      psutil
      pydantic
      pygments
      pyjwt
      python-daemon
      python-dateutil
      python-slugify
      requests
      rich-argparse
      rich
      setproctitle
      sqlalchemy-jsonfield
      sqlalchemy-utils
      sqlalchemy
      svcs
      tabulate
      tenacity
      termcolor
      universal-pathlib
      uuid6
      a2wsgi
      aiosqlite
      alembic
      argcomplete
      asgiref
      cadwyn
      colorlog
      cron-descriptor
      croniter
      cryptography
      dill
      fastapi
      flask
      gunicorn
      httpx
      itsdangerous
      jinja2
      jsonschema
      lazy-object-proxy
      libcst
      linkify-it-py
      marshmallow-oneofschema
      methodtools
      opentelemetry-api
      opentelemetry-exporter-otlp
      pendulum
      psutil
      pygments
      pyjwt
      python-daemon
      python-dateutil
      python-slugify
      requests
      requests-toolbelt
      rfc3339-validator
      rich-argparse
      rich
      setproctitle
      sqlalchemy
      sqlalchemy-jsonfield
      sqlalchemy-utils
      svcs
      tabulate
      tenacity
      termcolor
      tomli
      trove-classifiers
      universal-pathlib
      uuid6
      werkzeug
    ]
    ++ providerPackages;
  };

  taskSdk = buildPythonPackage {
    pname = "task-sdk";
    version = "1.0.0"; # Replace with the actual version if needed
    src = "${airflow-src}/task-sdk";
    pyproject = true;
    build-system = [
      hatchling
      attrs
    ];

    dependencies = [
      aiologic
      fsspec
      httpx
      jinja2
      methodtools
      msgspec
      pendulum
      psutil
      python-dateutil
      retryhttp
      structlog
      airflowCore
    ];
  };

in
buildPythonApplication {
  pname = "apache-airflow";
  inherit version;
  src = airflow-src;
  pyproject = true;
  build-system = [ hatchling ];

  postInstall = ''
    # Remove the default airflow.cfg file
    #rm -f $out/airflow.cfg
    # Create a symlink to the airflow-core package
    mkdir -p $out/bin
    ln -s ${airflowCore}/bin/airflow $out/bin/airflow
  '';

  nativeBuildInputs = [ writableTmpDirAsHomeHook ];

  dependencies = [
    cadwyn
    svcs
    taskSdk
    pandas
    uvicorn
  ]
  ++ providerPackages;

  propagatedBuildInputs = [
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
    airflowCore
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
  ]
  ++ providerImports;

  installCheckPhase = ''
    export AIRFLOW_HOME=$HOME
    export AIRFLOW__CORE__UNIT_TEST_MODE=True
    export AIRFLOW_DB="$HOME/airflow.db"
    export PATH=$PATH:$out/bin

    airflow version
    airflow db reset -y
  '';

  pytestFlagsArray = [
    "tests/core/test_core.py"
  ];

  disabledTests = lib.optionals stdenv.hostPlatform.isDarwin [
    "bash_operator_kill" # psutil.AccessDenied
  ];

  passthru = {
    updateScript = ./update.sh;
    core = airflowCore;
  };

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
