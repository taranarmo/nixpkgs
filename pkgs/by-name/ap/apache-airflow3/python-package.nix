{
  lib,
  stdenv,
  python,
  buildPythonPackage,
  buildPythonApplication,
  fetchFromGitHub,
  writableTmpDirAsHomeHook,
  # build dependencies
  gitdb,
  gitpython,
  hatchling,
  packaging,
  pathspec,
  pluggy,
  smmap,
  tomli,
  trove-classifiers,
  # runtime dependencies
  a2wsgi,
  aiosqlite,
  alembic,
  argcomplete,
  asgiref,
  attrs,
  blinker,
  cadwyn,
  colorlog,
  configupdater,
  connexion,
  cron-descriptor,
  croniter,
  cryptography,
  deprecated,
  dill,
  fastapi,
  flask,
  flask-caching,
  flask-session,
  flask-wtf,
  flit-core,
  fsspec,
  google-re2,
  gunicorn,
  httpx,
  itsdangerous,
  jinja2,
  jsonschema,
  lazy-object-proxy,
  libcst,
  linkify-it-py,
  lockfile,
  markdown-it-py,
  markupsafe,
  marshmallow-oneofschema,
  mdit-py-plugins,
  methodtools,
  msgspec,
  opentelemetry-api,
  opentelemetry-exporter-otlp,
  pandas,
  pendulum,
  psutil,
  pydantic,
  pygments,
  pyjwt,
  python-daemon,
  python-dateutil,
  python-nvd3,
  python-slugify,
  requests,
  requests-toolbelt,
  retryhttp,
  rfc3339-validator,
  rich,
  rich-argparse,
  setproctitle,
  sqlalchemy,
  sqlalchemy-jsonfield,
  sqlalchemy-utils,
  structlog,
  svcs,
  tabulate,
  tenacity,
  termcolor,
  universal-pathlib,
  uuid6,
  uvicorn,
  werkzeug,

  enabledProviders ? [ ],
}:
let
  version = "3.0.4";

  airflow-src = fetchFromGitHub {
    owner = "apache";
    repo = "airflow";
    tag = "${version}";
    forceFetchGit = true;
    hash = "sha256-3yo+lW7iXld90QKkimVbVQ4klNHv65Nu+p0aWuj7KlQ=";
  };

  requiredProviders = [
    "common_compat"
    "common_io"
    "common_sql"
    "smtp"
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
    pyproject = true;

    doCheck = false;

    postPatch = ''
      # remove cyclic dep
      substituteInPlace airflow-core/pyproject.toml \
        --replace-fail '"apache-airflow-task-sdk<1.1.0,>=1.0.3",' ' '
    '';

    build-system = [
      gitdb
      gitpython
      hatchling
      packaging
      pathspec
      pluggy
      smmap
      tomli
      trove-classifiers
    ];

    dependencies = [
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

  postInstall = ''
    # Create a symlink to the airflow-core package
    mkdir -p $out/bin
    ln -s ${airflowCore}/bin/airflow $out/bin/airflow
  '';

  nativeBuildInputs = [ writableTmpDirAsHomeHook ];

  build-system = [
    gitdb
    gitpython
    hatchling
    packaging
    pathspec
    pluggy
    smmap
    tomli
    trove-classifiers
  ];

  dependencies = [
    a2wsgi
    airflowCore
    alembic
    argcomplete
    asgiref
    attrs
    blinker
    cadwyn
    colorlog
    configupdater
    connexion
    cron-descriptor
    croniter
    cryptography
    deprecated
    dill
    fastapi
    flask
    flask-caching
    flask-session
    flask-wtf
    fsspec
    google-re2
    gunicorn
    httpx
    itsdangerous
    jinja2
    jsonschema
    lazy-object-proxy
    libcst
    linkify-it-py
    lockfile
    markdown-it-py
    markupsafe
    marshmallow-oneofschema
    mdit-py-plugins
    methodtools
    opentelemetry-api
    opentelemetry-exporter-otlp
    pandas
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
    rich
    rich-argparse
    setproctitle
    sqlalchemy
    sqlalchemy-jsonfield
    sqlalchemy-utils
    svcs
    tabulate
    taskSdk
    tenacity
    termcolor
    universal-pathlib
    uuid6
    uvicorn
    werkzeug
  ]
  ++ providerPackages;

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
