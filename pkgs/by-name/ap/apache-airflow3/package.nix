{
  fetchFromGitHub,
  fetchPypi,
  python3,
}:

let
  python = python3.override {
    self = python;
    packageOverrides = pySelf: pySuper: {
      connexion = pySuper.connexion.overridePythonAttrs (o: rec {
        version = "2.14.2";
        src = fetchFromGitHub {
          owner = "spec-first";
          repo = "connexion";
          rev = "refs/tags/${version}";
          hash = "sha256-1v1xCHY3ZnZG/Vu9wN/it7rLKC/StoDefoMNs+hMjIs=";
        };
        nativeBuildInputs = with pySelf; [
          setuptools
        ];
        pythonRelaxDeps = [
          "werkzeug"
        ];
        propagatedBuildInputs = with pySelf; [
          aiohttp
          aiohttp-jinja2
          aiohttp-swagger
          clickclick
          flask
          inflection
          jsonschema
          openapi-spec-validator
          packaging
          pyyaml
          requests
          swagger-ui-bundle
        ];
        nativeCheckInputs = with pySelf; [
          aiohttp-remotes
          decorator
          pytest-aiohttp
          pytestCheckHook
          testfixtures
        ];
        disabledTests = [
          "test_app"
          "test_invalid_type"
          "test_openapi_yaml_behind_proxy"
          "test_swagger_ui"
        ];
        postPatch = ''
          substituteInPlace connexion/__init__.py \
            --replace "2020.0.dev1" "${version}"
        '';
      });
      werkzeug = pySuper.werkzeug.overridePythonAttrs (o: rec {
        version = "2.3.8";
        src = fetchPypi {
          pname = "werkzeug";
          inherit version;
          hash = "sha256-VUslfHS763oNJUFgpPj/4YUkP1KlIDUGC3Ycpi2XfwM=";
        };
        nativeCheckInputs = with pySelf; [
          pytest-xprocess
        ];
      });
      flask = pySuper.flask.overridePythonAttrs (o: rec {
        version = "2.2.5";
        src = fetchPypi {
          pname = "Flask";
          inherit version;
          hash = "sha256-7e6bCn/yZiG9WowQ/0hK4oc3okENmbC7mmhQx/uXeqA=";
        };
        nativeBuildInputs = (o.nativeBuildInputs or [ ]) ++ [
          pySelf.setuptools
        ];
        doCheck = false;
      });
      flask-login = pySuper.flask-login.overridePythonAttrs (o: rec {
        version = "0.6.2";
        src = fetchPypi {
          pname = "Flask-Login";
          inherit version;
          hash = "sha256-wKe6qf3ESM3T3W8JOd9y7sUXey96vmy4L8k00pyqycM=";
        };
        build-system = [ pySelf.setuptools ];
        doCheck = false;
        nativeBuildInputs = with pySelf; [
          semantic-version
        ];
      });
      flask-session = pySuper.flask-session.overridePythonAttrs (o: rec {
        version = "0.5.0";
        src = fetchFromGitHub {
          owner = "palletc-eco";
          repo = "flask-session";
          rev = "refs/tags/${version}";
          hash = "sha256-t8w6ZS4gBDpnnKvL3DLtn+rRLQNJbrT2Hxm4f3+a3Xc=";
        };
        nativeCheckInputs = with pySelf; [ pytestCheckHook ];
        pytestFlagsArray = [ "-k" "'null_session or filesystem_session'" ];
        dependencies = with pySelf; [ flask_sqlalchemy cachelib ];
        disabledTests = [];
        disabledTestPaths = [];
        preCheck = "";
        postCheck = "";
      });
      ## flask-appbuilder doesn't work with sqlalchemy 2.x, flask-appbuilder 3.x
      ## https://github.com/dpgaspar/Flask-AppBuilder/issues/2038
      flask-appbuilder = pySuper.flask-appbuilder.overridePythonAttrs (o: rec {
        version = "4.5.3";
        src = fetchPypi {
          pname = "Flask-AppBuilder";
          inherit version;
          hash = "sha256-Lz+VO4E0vtAu0CNqt+hebDVLGzaABp12363AF+sFxWE=";
        };
        meta.broken = false;
        pythonImportsCheck = [ ];
      });
      ## a knock-on effect from overriding the sqlalchemy version
      flask-sqlalchemy = pySuper.flask-sqlalchemy.overridePythonAttrs (o: {
        src = fetchPypi {
          pname = "Flask-SQLAlchemy";
          version = "2.5.1";
          hash = "sha256-K9pEtD58rLFdTgX/PMH4vJeTbMRkYjQkECv8LDXpWRI=";
        };
        nativeBuildInputs = with pySelf; [ pdm-pep517 ];
        format = "setuptools";
        doCheck = false;
      });
      #flask-sqlalchemy = pySuper.flask-sqlalchemy.overridePythonAttrs (o: {
      #  src = fetchPypi {
      #    pname = "Flask-SQLAlchemy";
      #    version = "3.0.1";
      #    hash = "sha256-Cl1YZ3SUmFbk8f6L46ZMWUYVlZ454rBB6Ie6xcdWvEI=";
      #  };
      #  nativeBuildInputs = with pySelf; [ pdm-pep517 ];
      #  format = "pyproject";
      #  #format = "setuptools";
      #});
      httpcore = pySuper.httpcore.overridePythonAttrs (o: rec {
        # nullify upstream's pytest flags which cause
        # "TLS/SSL connection has been closed (EOF)"
        # with pytest-httpbin 1.x
        preCheck = ''
          substituteInPlace pyproject.toml \
            --replace '[tool.pytest.ini_options]' '[tool.notpytest.ini_options]'
        '';
        doCheck = false;
      });
      pytest-httpbin = pySuper.pytest-httpbin.overridePythonAttrs (o: rec {
        version = "1.0.2";
        src = fetchFromGitHub {
          owner = "kevin1024";
          repo = "pytest-httpbin";
          rev = "refs/tags/v${version}";
          hash = "sha256-S4ThQx4H3UlKhunJo35esPClZiEn7gX/Qwo4kE1QMTI=";
        };
        doCheck = false;
      });
      ## apache-airflow doesn't work with sqlalchemy 2.x
      ## https://github.com/apache/airflow/issues/28723
      sqlalchemy = pySuper.sqlalchemy_1_4;

      # gitpython = pySuper.gitpython.overridePythonAttrs (o: rec {
      #   version = "3.1.44";
      #   src = fetchFromGitHub {
      #     owner = "gitpython-developers";
      #     repo = "GitPython";
      #     rev = "refs/tags/${version}";
      #     hash = "sha256-KnKaBv/tKk4wiGWUWCEgd1vgrTouwUhqxJ1/nMjRaWk=";
      #   };
      # });
      gitdb = pySuper.gitdb.overridePythonAttrs (o: rec {
        version = "4.0.12";
        src = fetchFromGitHub {
          owner = "gitpython-developers";
          repo = "gitdb";
          rev = "refs/tags/${version}";
          hash = "sha256-24nOiKHmrhdF0BAmx+1AxaDy8C+qlNFvpuZUyU+tMFU=";
        };
      });
      # hatchling = pySuper.hatchling.overridePythonAttrs (o: rec {
      #   pname = "hatchling";
      #   version = "1.27.0";
      #   src = fetchPypi {
      #     inherit pname version;
      #     hash = "sha256-lxwpbZgZq7OBERL8UsepdRyNOBiY82Uzuxb5eR6UH9Y=";
      #   };
      # });
      # packaging = pySuper.packaging.overridePythonAttrs (o: rec {
      #   version = "24.2";
      #   src = fetchFromGitHub {
      #     owner = "pypa";
      #     repo = "packaging";
      #     rev = "refs/tags/${version}";
      #     hash = "sha256-7B/d9AG6D8CULM+Ut7g5MogEiXtvVgGvsu3comHHoos=";
      #   };
      # });
      # pathspec = pySuper.pathspec.overridePythonAttrs (o: rec {
      #   version = "0.12.1";
      #   src = fetchFromGitHub {
      #     owner = "cpburnz";
      #     repo = "python-pathspec";
      #     rev = "refs/tags/v${version}";
      #     hash = "sha256-jv6uCN94LRfDy+583omvgmL96D2GcF8WhAM8V9ezH/0=";
      #   };
      # });
      # pluggy = pySuper.pluggy.overridePythonAttrs (o: rec {
      #   version = "1.5.0";
      #   src = fetchFromGitHub {
      #     owner = "pytest-dev";
      #     repo = "pluggy";
      #     rev = "refs/tags/${version}";
      #     hash = "sha256-f0DxyZZk6RoYtOEXLACcsOn2B+Hot4U4g5Ogr/hKmOE=";
      #   };
      # });
      smmap = pySuper.smmap.overridePythonAttrs (o: rec {
        version = "5.0.2";
        src = fetchFromGitHub {
          owner = "gitpython-developers";
          repo = "smmap";
          rev = "refs/tags/v${version}";
          hash = "sha256-0Y175kjv/8UJpSxtLpWH4/VT7JrcVPAq79Nf3rtHZZM=";
        };
      });
      # tomli = pySuper.tomli.overridePythonAttrs (o: rec {
      #   version = "2.2.1";
      #   src = fetchFromGitHub {
      #     owner = "hukkin";
      #     repo = "tomli";
      #     rev = "refs/tags/${version}";
      #     hash = "sha256-4MWp9pPiUZZkjvGXzw8/gDele743NBj8uG4jvK2ohUM=";
      #   };
      # });
      trove-classifiers = pySuper.trove-classifiers.overridePythonAttrs (o: rec {
        version = "2025.3.13.13";
        src = fetchPypi {
          inherit version;
          pname = "trove_classifiers";
          hash = "sha256-Kl4k3a+yDaIiWoJf4WfE/U7L8xLO9DENZ/GdxA2n3I0=";
        };
      });
      # trove-classifiers = pySuper.trove-classifiers.overridePythonAttrs (o: rec {
      #   version = "2024.10.21.16";
      #   src = fetchPypi {
      #     pname = "trove_classifiers";
      #     inherit version;
      #     hash = "sha256-F8vQVdZ9Xp2d5jKTqHMpQ/q8IVdOTHt07fEStJKM9fM=";
      #   };
      # });

      apache-airflow = pySelf.callPackage ./python-package.nix { };
    };
  };
in
# See note in ./python-package.nix for
# instructions on manually testing the web UI
with python.pkgs;
(toPythonApplication apache-airflow).overrideAttrs (previousAttrs: {
  # Provide access to airflow's modified python package set
  # for the cases where external scripts need to import
  # airflow modules, though *caveat emptor* because many of
  # these packages will not be built by hydra and many will
  # not work at all due to the unexpected version overrides
  # here.
  passthru = (previousAttrs.passthru or { }) // {
    pythonPackages = python.pkgs;
  };
})
