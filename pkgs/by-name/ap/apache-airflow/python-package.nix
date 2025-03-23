{
  lib,
  mkYarnPackage,
  fetchYarnDeps,
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

  setproctitle,
  pygments,
  pendulum,

  alembic,
  argcomplete,
  asgiref,
  attrs,
  blinker,
  # cached-property,
  # cattrs,
  # clickclick,
  colorlog,
  configupdater,
  connexion,
  cron-descriptor,
  croniter,
  cryptography,
  deprecated,
  dill,
  flask,
  # flask-login,
  # flask-appbuilder,
  flask-caching,
  flask-session,
  flask-wtf,
  fsspec,
  # gitpython,
  google-re2,
  # graphviz,
  gunicorn,
  httpx,
  # iso8601,
  # importlib-resources,
  importlib-metadata,
  # inflection,
  itsdangerous,
  jinja2,
  jsonschema,
  lazy-object-proxy,
  linkify-it-py,
  lockfile,
  # markdown,
  markdown-it-py,
  markupsafe,
  marshmallow-oneofschema,
  mdit-py-plugins,
  methodtools,
  # numpy,
  # openapi-spec-validator,
  opentelemetry-api,
  opentelemetry-exporter-otlp,
  # pandas,
  # pathspec,
  # pendulum,
  psutil,
  # pydantic,
  # pygments,
  pyjwt,
  python-daemon,
  python-dateutil,
  python-nvd3,
  python-slugify,
  # python3-openid,
  pythonOlder,
  # pyyaml,
  requests,
  requests-toolbelt,
  rfc3339-validator,
  rich,
  rich-argparse,
  # setproctitle,
  sqlalchemy,
  sqlalchemy-jsonfield,
  # swagger-ui-bundle,
  tabulate,
  tenacity,
  termcolor,
  # typing-extensions,
  # unicodecsv,
  universal-pathlib,
  werkzeug,
  # freezegun,
  # pytest-asyncio,
  # pytestCheckHook,
  # time-machine,
  writeScript,

  # Extra airflow providers to enable
  enabledProviders ? [ ],
}:
let
  version = "2.10.5";

  airflow-src = fetchFromGitHub {
    owner = "apache";
    repo = "airflow";
    rev = "refs/tags/${version}";
    # Download using the git protocol rather than using tarballs, because the
    # GitHub archive tarballs don't appear to include tests
    forceFetchGit = true;
    hash = "sha256-q5/CM+puXE31+15F3yZmcrR74LrqHppdCDUqjLQXPfk=";
  };

  # airflow bundles a web interface, which is built using webpack by an undocumented shell script in airflow's source tree.
  # This replicates this shell script, fixing bugs in yarn.lock and package.json

  airflow-frontend = mkYarnPackage rec {
    name = "airflow-frontend";

    src = "${airflow-src}/airflow/www";
    packageJSON = ./package.json;

    offlineCache = fetchYarnDeps {
      yarnLock = "${src}/yarn.lock";
      hash = "sha256-hKgtMH4c8sPRDLPLVn+H8rmwc2Q6ei6U4er6fGuFn4I=";
    };

    distPhase = "true";

    # The webpack license plugin tries to create /3rd-party-licenses when given the
    # original relative path
    postPatch = ''
      sed -i 's!../../../../3rd-party-licenses/LICENSES-ui.txt!/3rd-party-licenses/LICENSES-ui.txt!' webpack.config.js
    '';

    configurePhase = ''
      cp -r $node_modules node_modules
    '';

    buildPhase = ''
      yarn --offline build
      find package.json yarn.lock static/css static/js -type f | sort | xargs md5sum > static/dist/sum.md5
    '';

    installPhase = ''
      mkdir -p $out/static/
      cp -r static/dist $out/static
    '';
  };

  getProviderVersion = providerPath:
    let
      initPy = builtins.readFile "${airflow-src}/airflow/providers/${providerPath}/__init__.py";
      #versionRegex = builtins.match "^\s*__version__\s*=\s*['\"]([^'\"]*)['\"]" initPy;
      versionRegex = builtins.match ".*__version__[[:space:]]*=[[:space:]]*[\"']([^\"']+)[\"'].*" initPy;
    in
      if versionRegex != null then
        builtins.elemAt versionRegex 0
      else
        builtins.throw "Could not find __version__ in ${airflow-src}/airflow/providers/${providerPath}/__init__.py";

  buildProvider = providerPath: buildPythonPackage {
    pname = "apache-airflow-providers-${lib.replaceStrings ["/"] ["-"] providerPath}";
    version = getProviderVersion providerPath;
    src = "${airflow-src}/airflow/providers/${providerPath}";
    pyproject = false;
  };

  apache-airflow-providers-common-compat = buildProvider "common/compat";
  apache-airflow-providers-common-io = buildProvider "common/io";
  apache-airflow-providers-common-sql = buildProvider "common/sql";
  apache-airflow-providers-fab = buildProvider "fab";
  apache-airflow-providers-ftp = buildProvider "ftp";
  apache-airflow-providers-http = buildProvider "http";
  apache-airflow-providers-imap = buildProvider "imap";
  apache-airflow-providers-smtp = buildProvider "smtp";
  apache-airflow-providers-sqlite = buildProvider "sqlite";

  # Import generated file with metadata for provider dependencies and imports.
  # Enable additional providers using enabledProviders above.
  providers = import ./providers.nix;
  getProviderDeps = provider: map (dep: python.pkgs.${dep}) providers.${provider}.deps;
  getProviderImports = provider: providers.${provider}.imports;
  providerDependencies = lib.concatMap getProviderDeps enabledProviders;
  providerImports = lib.concatMap getProviderImports enabledProviders;
in
buildPythonApplication rec {
  pname = "apache-airflow";
  inherit version;
  src = airflow-src;
  pyproject=true;

  nativeBuildInputs = [ python.pkgs.hatchling ];

  disabled = pythonOlder "3.8";

  dontCheckRuntimeDeps = true;

  propagatedBuildInputs =
    [
  apache-airflow-providers-common-compat
  apache-airflow-providers-common-io
  apache-airflow-providers-common-sql
  apache-airflow-providers-fab
  apache-airflow-providers-ftp
  apache-airflow-providers-http
  apache-airflow-providers-imap
  apache-airflow-providers-smtp
  apache-airflow-providers-sqlite
      gitpython
      gitdb
      packaging
      pathspec
      pluggy
      smmap
      tomli
      trove-classifiers

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

 #     alembic
 #     argcomplete
 #     asgiref
 #     attrs
 #     blinker
 #     cached-property
 #     cattrs
 #     clickclick
 #     colorlog
 #     configupdater
 #     connexion
 #     cron-descriptor
 #     croniter
 #     cryptography
 #     deprecated
 #     dill
 #     flask
 #     flask-appbuilder
 #     flask-caching
 #     flask-session
 #     flask-wtf
 #     flask-login
 #     gitpython
 #     google-re2
 #     graphviz
 #     gunicorn
 #     httpx
 #     iso8601
 #     importlib-resources
 #     inflection
 #     itsdangerous
 #     jinja2
 #     jsonschema
 #     lazy-object-proxy
 #     linkify-it-py
 #     lockfile
 #     markdown
 #     markupsafe
 #     marshmallow-oneofschema
 #     mdit-py-plugins
 #     numpy
 #     openapi-spec-validator
 #     opentelemetry-api
 #     opentelemetry-exporter-otlp
 #     pandas
 #     pathspec
 #     pendulum
 #     psutil
 #     pydantic
 #     pygments
 #     pyjwt
 #     python-daemon
 #     python-dateutil
 #     python-nvd3
 #     python-slugify
 #     python3-openid
 #     pyyaml
 #     rich
 #     rich-argparse
 #     setproctitle
 #     sqlalchemy
 #     sqlalchemy-jsonfield
 #     swagger-ui-bundle
 #     tabulate
 #     tenacity
 #     termcolor
 #     typing-extensions
 #     unicodecsv
 #     werkzeug
    ]
    ++ lib.optionals (pythonOlder "3.9") [
      importlib-metadata
    ]
    ++ providerDependencies;

  #nativeCheckInputs = [
  #  freezegun
  #  pytest-asyncio
  #  pytestCheckHook
  #  time-machine
  #];

  # By default, source code of providers is included but unusable due to missing
  # transitive dependencies. To enable a provider, add it to extraProviders
  # above
  INSTALL_PROVIDERS_FROM_SOURCES = "true";

  postPatch =
    ''
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      # Fix failing test on Hydra
      substituteInPlace airflow/utils/db.py \
        --replace-fail "/tmp/sqlite_default.db" "$TMPDIR/sqlite_default.db"
    '';

  pythonRelaxDeps = [
    "colorlog"
    "flask-appbuilder"
    "opentelemetry-api"
    "pathspec"
    "trove-classifiers"
  ];

  # allow for gunicorn processes to have access to Python packages
  makeWrapperArgs = [
    "--prefix PYTHONPATH : $PYTHONPATH"
  ];

  postInstall = ''
    #cp -rv ${airflow-frontend}/static/dist $out/${python.sitePackages}/airflow/www/static
    # Needed for pythonImportsCheck below
    export HOME=$(mktemp -d)
  '';

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

  # Updates yarn.lock and package.json
  passthru.updateScript = writeScript "update.sh" ''
    #!/usr/bin/env nix-shell
   #!nix-shell -i bash -p common-updater-scripts curl pcre "python3.withPackages (ps: with ps; [ pyyaml ])" yarn2nix

    set -euo pipefail

   # Get new version
    new_version="$(curl -s https://airflow.apache.org/docs/apache-airflow/stable/release_notes.html |
      pcregrep -o1 'Airflow ([0-9.]+).' | head -1)"
    update-source-version ${pname} "$new_version"

   # Update frontend
   cd ./pkgs/servers/apache-airflow
   curl -O https://raw.githubusercontent.com/apache/airflow/$new_version/airflow/www/yarn.lock
   curl -O https://raw.githubusercontent.com/apache/airflow/$new_version/airflow/www/package.json
   yarn2nix > yarn.nix

    # update provider dependencies
    ./update-providers.py
  '';

  # Note on testing the web UI:
  # You can (manually) test the web UI as follows:
  #
  #   nix shell .#apache-airflow
  #   airflow db reset  # WARNING: this will wipe any existing db state you might have!
  #   airflow db init
  #   airflow standalone
  #
  # Then navigate to the localhost URL using the credentials printed, try
  # triggering the 'example_bash_operator' and 'example_bash_operator' DAGs and
  # see if they report success.

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
