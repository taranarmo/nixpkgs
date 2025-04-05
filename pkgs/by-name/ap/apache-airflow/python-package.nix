{
  lib,
  alembic,
  argcomplete,
  asgiref,
  attrs,
  blinker,
  buildPythonApplication,
  colorlog,
  configupdater,
  connexion,
  cron-descriptor,
  croniter,
  cryptography,
  deprecated,
  dill,
  fetchFromGitHub,
  fetchYarnDeps,
  flask,
  flask-appbuilder,
  flask-caching,
  flask-session,
  flask-wtf,
  fsspec,
  gitdb,
  gitpython,
  google-re2,
  gunicorn,
  hatchling,
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
  mkYarnPackage,
  opentelemetry-api,
  opentelemetry-exporter-otlp,
  packaging,
  pandas,
  pathspec,
  pendulum,
  pluggy,
  psutil,
  pygments,
  pyjwt,
  pytest-asyncio,
  pytestCheckHook,
  python,
  python-daemon,
  python-dateutil,
  python-nvd3,
  python-slugify,
  requests,
  requests-toolbelt,
  rfc3339-validator,
  rich,
  rich-argparse,
  setproctitle,
  smmap,
  sqlalchemy,
  sqlalchemy-jsonfield,
  stdenv,
  tabulate,
  tenacity,
  termcolor,
  tomli,
  trove-classifiers,
  universal-pathlib,
  werkzeug,
  writeScript,

  # Extra airflow providers to enable
  enabledProviders ? [
    "common_compat"
    "common_io"
    "common_sql"
    "fab"
    "ftp"
    "http"
    "imap"
    "smtp"
    "sqlite"
  ],
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

  # Import generated file with metadata for provider dependencies and imports
  providers = import ./providers.nix;

  # Map provider names to their actual directory paths
  providerMapping = {
    common_compat = "common/compat";
    common_io = "common/io";
    common_sql = "common/sql";
    # Add other mappings if needed
  };

  # Helper functions to get provider information
  getProviderPath = provider: if lib.hasAttr provider providerMapping then providerMapping.${provider} else provider;
  getProviderDeps = provider: map (dep: python.pkgs.${dep}) providers.${provider}.deps;
  getProviderImports = provider: providers.${provider}.imports;
  providerImports = lib.concatMap getProviderImports enabledProviders;

  # Build a provider package using the modified approach
  buildProvider = provider: let
    providerPath = getProviderPath provider;
  in
    python.pkgs.buildPythonPackage {
      pname = "apache-airflow-providers-${provider}";
      version = "unstable";  # Will be extracted in the build phase
      format = "other";  # Don't use setuptools or other build systems

      src = airflow-src;

      propagatedBuildInputs = getProviderDeps provider;
      dependencies = [ packaging ];
      # pythonImportsCheck = providers.${provider}.imports;

      buildPhase = ''
        # Extract version from the provider's __init__.py file
        if [ -f "airflow/providers/${providerPath}/__init__.py" ]; then
          version=$(grep -oP "(?<=__version__ = ')[^']+" "airflow/providers/${providerPath}/__init__.py" || echo "0.0.0")
          echo "Provider ${provider} version: $version"
        else
          echo "Error: __init__.py not found for provider ${provider} at path airflow/providers/${providerPath}"
          exit 1
        fi
      '';

      installPhase = ''
        # Create directory structure
        mkdir -p $out/${python.sitePackages}/airflow/providers

        # Copy the provider directory
        if [ -d "airflow/providers/${providerPath}" ]; then
          mkdir -p $out/${python.sitePackages}/airflow/providers/$(dirname "${providerPath}")
          cp -r airflow/providers/${providerPath} $out/${python.sitePackages}/airflow/providers/$(dirname "${providerPath}")

          # Create parent __init__.py files
          touch $out/${python.sitePackages}/airflow/__init__.py
          touch $out/${python.sitePackages}/airflow/providers/__init__.py

          # Create any needed intermediate __init__.py files for nested providers
          providerDir=$(dirname "${providerPath}")
          while [ "$providerDir" != "." ] && [ -n "$providerDir" ]; do
            mkdir -p $out/${python.sitePackages}/airflow/providers/$providerDir
            touch $out/${python.sitePackages}/airflow/providers/$providerDir/__init__.py
            providerDir=$(dirname "$providerDir")
          done

          # Create egg-info for package discovery
          mkdir -p $out/${python.sitePackages}/apache_airflow_providers_${lib.replaceStrings ["/"] ["_"] provider}.egg-info
          cat > $out/${python.sitePackages}/apache_airflow_providers_${lib.replaceStrings ["/"] ["_"] provider}.egg-info/PKG-INFO <<EOF
  Metadata-Version: 2.1
  Name: apache-airflow-providers-${lib.replaceStrings ["/"] ["-"] provider}
  Version: $version
  Summary: Apache Airflow Provider for ${provider}
  EOF
        else
          echo "Provider directory not found: airflow/providers/${providerPath}"
          exit 1
        fi
      '';
    };

  # Map function to build all enabled providers
  providerPackages = map buildProvider enabledProviders;

  task-sdk = python.pkgs.buildPythonPackage {
    pname = "apache-airflow-task-sdk";
    version = "unstable";  # Will be extracted in the build phase
    format = "other";  # Don't use setuptools or other build systems

    src = airflow-src;

    # Common airflow provider dependencies that task SDK might need
    # You might need to adjust these based on actual requirements
    propagatedBuildInputs = [
      python.pkgs.markupsafe
      python.pkgs.jinja2
      python.pkgs.sqlalchemy
    ];

    # Disable imports check
    # doCheck = false;

    buildPhase = ''
      # Extract version from the task/__init__.py file
      if [ -f "airflow/task/__init__.py" ]; then
        version=$(grep -oP "(?<=__version__ = ')[^']+" "airflow/task/__init__.py" || echo "0.0.0")
        echo "Task SDK version: $version"
      else
        # Fallback to the main airflow version
        version="${version}"
        echo "Using main Airflow version for task SDK: $version"
      fi
    '';

    installPhase = ''
      # Create directory structure
      mkdir -p $out/${python.sitePackages}/airflow

      # Create a proper airflow/__init__.py with version information
      cat > $out/${python.sitePackages}/airflow/__init__.py <<EOF
  # This is a minimal __init__.py to satisfy task SDK imports
  __version__ = "${version}"
  EOF

      # Copy the task directory
      if [ -d "airflow/task" ]; then
        cp -r airflow/task $out/${python.sitePackages}/airflow/

        # Create egg-info for package discovery
        mkdir -p $out/${python.sitePackages}/apache_airflow_task_sdk.egg-info
        cat > $out/${python.sitePackages}/apache_airflow_task_sdk.egg-info/PKG-INFO <<EOF
  Metadata-Version: 2.1
  Name: apache-airflow-task-sdk
  Version: $version
  Summary: Apache Airflow Task SDK
  EOF
      else
        echo "Task SDK directory not found: airflow/task"
        exit 1
      fi
    '';
  };

  api-fastapi = python.pkgs.buildPythonPackage {
    pname = "apache-airflow-api-fastapi";
    version = "unstable";
    format = "other";
    src = airflow-src;
    propagatedBuildInputs = [
      python.pkgs.fastapi
      python.pkgs.pydantic
    ];
    buildPhase = ''
      if [ -f "airflow/api/__init__.py" ]; then
        version=$(grep -oP "(?<=__version__ = ')[^']+" "airflow/api/__init__.py" || echo "0.0.0")
        echo "API FastAPI version: $version"
      else
        version="${version}"
        echo "Using main Airflow version for API FastAPI: $version"
      fi
    '';
    installPhase = ''
      mkdir -p $out/${python.sitePackages}/airflow
      if [ -d "airflow/api" ]; then
        cp -r airflow/api $out/${python.sitePackages}/airflow/
        mkdir -p $out/${python.sitePackages}/apache_airflow_api_fastapi.egg-info
        cat > $out/${python.sitePackages}/apache_airflow_api_fastapi.egg-info/PKG-INFO <<EOF
  Metadata-Version: 2.1
  Name: apache-airflow-api-fastapi
  Version: $version
  Summary: Apache Airflow API FastAPI
  EOF
      else
        echo "API FastAPI directory not found: airflow/api"
        exit 1
      fi
    '';
  };

in
buildPythonApplication rec {
  pname = "apache-airflow";
  inherit version;
  src = airflow-src;
  pyproject = true;

  nativeBuildInputs = [ hatchling ];

  dontCheckRuntimeDeps = true;

  dependencies = [
    pandas
    providerPackages
    alembic
    argcomplete
    # asgiref
    # attrs
    # blinker
    colorlog
    # configupdater
    connexion
    cron-descriptor
    croniter
    cryptography
    # deprecated
    dill
    # flask
    # flask-appbuilder
    flask-caching
    flask-session
    # flask-wtf
    fsspec
    gitdb
    gitpython
    # google-re2
    # gunicorn
    # httpx
    # itsdangerous
    # jinja2
    # jsonschema
    lazy-object-proxy
    # linkify-it-py
    lockfile
    # markdown-it-py
    # markupsafe
    # marshmallow-oneofschema
    # mdit-py-plugins
    methodtools
    # opentelemetry-api
    # opentelemetry-exporter-otlp
    packaging
    pathspec
    pendulum
    pluggy
    psutil
    # pygments
    # pyjwt
    # python-daemon
    # python-dateutil
    # python-nvd3
    # python-slugify
    # requests
    # requests-toolbelt
    # rfc3339-validator
    # rich
    rich-argparse
    # setproctitle
    smmap
    sqlalchemy
    sqlalchemy-jsonfield
    tabulate
    tenacity
    # termcolor
    tomli
    trove-classifiers
    universal-pathlib
    # werkzeug
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
    configupdater
    marshmallow-oneofschema
  ];

  checkPhase = ''
    export PYTEST_ADDOPTS="--asyncio_default_fixture_loop_scope=cache"
  '';

  postPatch =
    ''
      substituteInPlace pyproject.toml \
        --replace-fail "\"/airflow/providers/\"," ""
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      # Fix failing test on Hydra
      substituteInPlace airflow/utils/db.py \
        --replace-fail "/tmp/sqlite_default.db" "$TMPDIR/sqlite_default.db"
    '';

  pythonRelaxDeps = [
    "colorlog"
    "pathspec"
    "trove-classifiers"
  ];

  # allow for gunicorn processes to have access to Python packages
  makeWrapperArgs = [
    "--prefix PYTHONPATH : $PYTHONPATH"
  ];

  postInstall = ''
    cp -rv ${airflow-frontend}/static/dist $out/${python.sitePackages}/airflow/www/static
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
  #   airflow version
  #   airflow db reset -y
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
