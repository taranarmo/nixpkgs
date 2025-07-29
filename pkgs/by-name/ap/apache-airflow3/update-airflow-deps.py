#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages(ps: [ps.requests ps.packaging ps.tomli])" -p nix-prefetch-github --argstr nixpkgs /home/taranarmo/dev/nixpkgs

import json
import logging
import re
import sys
import hashlib
import subprocess
from typing import Dict, List, Set, Tuple
from pathlib import Path

import requests
import tomli
from packaging.version import parse as parse_version
from packaging.specifiers import SpecifierSet


def get_github_hash(owner: str, repo: str, rev: str) -> str:
    logging.info(f"Fetching GitHub hash for {owner}/{repo}@{rev}")
    command = [
        "nix-prefetch-github",
        owner,
        repo,
        "--rev", rev,
    ]
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logging.error(f"Error fetching GitHub hash for {owner}/{repo}@{rev}: {e.stderr}")
        raise

def get_pypi_hash(package_name: str, version: str) -> str:
    logging.info(f"Fetching hash for {package_name}=={version}")
    url = f"https://pypi.org/pypi/{package_name}/{version}/json"
    response = requests.get(url)
    response.raise_for_status()
    data = response.json()

    sdist_url = None
    for file_info in data["urls"]:
        if file_info["packagetype"] == "sdist":
            sdist_url = file_info["url"]
            break

    if not sdist_url:
        raise ValueError(f"No sdist found for {package_name}=={version}")

    sdist_response = requests.get(sdist_url, stream=True)
    sdist_response.raise_for_status()

    hasher = hashlib.sha256()
    for chunk in sdist_response.iter_content(chunk_size=8192):
        hasher.update(chunk)

    return hasher.hexdigest()

AIRFLOW_VERSION = "3.0.3"
# GITHUB_BASE_URL = f"https://raw.githubusercontent.com/apache/airflow/{AIRFLOW_VERSION}" # Removed
PYPI_JSON_URL = "https://pypi.org/pypi/{package_name}/json"

AIRFLOW_LOCAL_PATH = "/home/taranarmo/dev/apache-airflow" # New: Local path to Airflow repo

GITHUB_PACKAGES = {
    "gitdb": {"owner": "gitpython-developers", "repo": "gitdb", "tag_prefix": "v"},
    "smmap": {"owner": "gitpython-developers", "repo": "smmap", "tag_prefix": "v"},
    "flask-session": {"owner": "palletc-eco", "repo": "flask-session", "tag_prefix": ""},
    "pluggy": {"owner": "pytest-dev", "repo": "pluggy", "tag_prefix": ""},
    "pytest-httpbin": {"owner": "kevin1024", "repo": "pytest-httpbin", "tag_prefix": "v"},
    "connexion": {"owner": "spec-first", "repo": "connexion", "tag_prefix": ""},
}

logging.basicConfig(level=logging.INFO)

def read_local_file(path: str):
    full_path = Path(AIRFLOW_LOCAL_PATH) / path
    try:
        with open(full_path, 'rb') as f:
            return f.read()
    except FileNotFoundError:
        logging.warning(f"File not found: {full_path}")
        raise
    except Exception as e:
        logging.error(f"Error reading local file {full_path}: {e}")
        raise

def get_pyproject_toml_content(repo_path: str) -> Dict:
    # url = f"{GITHUB_BASE_URL}/{repo_path}" # Removed
    try:
        content = read_local_file(repo_path)
        return tomli.loads(content.decode('utf-8'))
    except Exception as e:
        logging.error(f"Error parsing TOML from {repo_path}: {e}")
        sys.exit(1)

def parse_dependencies(toml_data: Dict) -> Set[str]:
    dependencies = set()
    
    # Direct dependencies
    direct_deps = toml_data.get('project', {}).get('dependencies', [])
    dependencies.update(direct_deps)

    # Optional dependencies
    optional_deps = toml_data.get('project', {}).get('optional-dependencies', {})
    for deps_list in optional_deps.values():
        dependencies.update(deps_list)
        
    return dependencies

def parse_dependency_specifier(dep_spec: str) -> Tuple[str, str]:
    match = re.match(r"([a-zA-Z0-9._-]+)([<>=~].*)?", dep_spec)
    if not match:
        logging.warning(f"Could not parse dependency specifier: {dep_spec}. Returning empty.")
        return "", ""
    package_name = match.group(1)
    version_specifier = match.group(2) if match.group(2) else ""
    return package_name, version_specifier

def normalize_package_name(name: str) -> str:
    # Convert to lowercase and replace hyphens/underscores with hyphens
    # This is a common normalization for Python package names
    return name.lower().replace('_', '-')

def resolve_version_from_pypi(package_name: str, version_specifier: str) -> str:
    normalized_name = normalize_package_name(package_name)
    
    # Handle direct version pins first
    if "==" in version_specifier:
        return version_specifier.split("==")[1].strip()

    # Remove environment markers like '; python_version < "3.11"'
    specifier_without_env = version_specifier.split(';')[0].strip()
    
    try:
        spec_set = SpecifierSet(specifier_without_env)
    except Exception as e:
        logging.warning(f"Could not parse specifier '{version_specifier}' for {package_name}: {e}. Skipping version resolution.")
        return "" # Return empty string if specifier is invalid

    response = requests.get(PYPI_JSON_URL.format(package_name=normalized_name))
    if response.status_code != 200:
        logging.warning(f"Could not fetch PyPI data for {normalized_name}. Status: {response.status_code}")
        return ""

    data = response.json()
    
    # Get all available versions and sort them
    available_versions = sorted([parse_version(v) for v in data['releases'].keys() if not parse_version(v).is_prerelease], reverse=True)

    for version in available_versions:
        if version in spec_set:
            return str(version)
            
    logging.warning(f"No matching version found on PyPI for {package_name} with specifier '{version_specifier}'")
    return ""

def generate_nix_overrides(pinned_deps: Dict[str, Dict[str, str]]) -> str:
    nix_content = """
# This file is generated by update-airflow-deps.py. Do not edit manually.
{
  lib,
  fetchPypi,
  fetchFromGitHub,
  # Add other fetchers as needed based on resolved packages
}:

self: super: {
"""

    for package, info in pinned_deps.items():
        version = info["version"]
        package_hash = info.get("hash") # Hash might be None for GitHub packages
        
        # Convert package name to Nixpkgs attribute name (e.g., 'apache-airflow-core' -> 'apacheAirflowCore')
        nix_attr_name = re.sub(r'[^a-zA-Z0-9]+', '', package.title())
        
        # Special handling for common packages that might have different Nixpkgs names
        if package == "apache-airflow-task-sdk":
            nix_attr_name = "apacheAirflowTaskSdk"
        elif package == "apache-airflow-core":
            nix_attr_name = "apacheAirflowCore"
        elif package.startswith("apache-airflow-providers-"):
            # Providers are handled separately, but if they appear as direct deps, we'll pin them
            provider_name = package.replace("apache-airflow-providers-", "").replace("-", "_")
            nix_attr_name = f"apacheAirflowProviders{provider_name.title().replace('_', '')}"
        
        if package in GITHUB_PACKAGES:
            github_info = GITHUB_PACKAGES[package]
            owner = github_info["owner"]
            repo = github_info["repo"]
            nix_content += f"  {nix_attr_name} = super.{nix_attr_name}.overrideAttrs (oldAttrs: {{\n"
            nix_content += f"    version = \"{version}\";\n"
            nix_content += f"    src = fetchFromGitHub {{\n"
            nix_content += f"      owner = \"{owner}\";\n"
            nix_content += f"      repo = \"{repo}\";\n"
            nix_content += f"      rev = \"refs/tags/v{version}\"; # Assuming tags are prefixed with 'v'\n"
            nix_content += f"      hash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\"; # TODO: Update hash using nix-prefetch-url\n"
            nix_content += "    };\n"
            nix_content += "  });\n"
        else:
            fetcher = "fetchPypi"
            nix_content += f"  {nix_attr_name} = super.{nix_attr_name}.overrideAttrs (oldAttrs: {{\n"
            nix_content += f"    version = \"{version}\";\n"
            nix_content += f"    src = {fetcher} {{\n"
            nix_content += f"      pname = \"{package}\";\n"
            nix_content += f"      version = \"{version}\";\n"
            nix_content += f"      hash = \"sha256-{package_hash}\";\n"
            nix_content += "    };\n"
            nix_content += "  });\n"

    nix_content += "}\n"
    return nix_content

def main():
    logging.info("Starting dependency pinning script for Apache Airflow.")

    airflow_toml = get_pyproject_toml_content("pyproject.toml")
    airflow_core_toml = get_pyproject_toml_content("airflow-core/pyproject.toml")

    airflow_dependencies = parse_dependencies(airflow_toml)
    airflow_core_dependencies = parse_dependencies(airflow_core_toml)

    airflow_pinned_dependencies: Dict[str, Dict[str, str]] = {}
    airflow_core_pinned_dependencies: Dict[str, Dict[str, str]] = {}

    for dep_spec in airflow_dependencies:
        package_name, version_specifier = parse_dependency_specifier(dep_spec)
        if package_name in ["apache-airflow", "apache-airflow-core", "apache-airflow-task-sdk"] or package_name.startswith("apache-airflow-providers-"):
            continue
        
        pinned_version = resolve_version_from_pypi(package_name, version_specifier)
        if pinned_version:
            if package_name in GITHUB_PACKAGES:
                github_info = GITHUB_PACKAGES[package_name]
                try:
                    package_hash = get_github_hash(github_info["owner"], github_info["repo"], f"{github_info["tag_prefix"]}{pinned_version}")
                    airflow_pinned_dependencies[package_name] = {"version": pinned_version, "hash": package_hash}
                except Exception as e:
                    logging.warning(f"Failed to fetch GitHub hash for {package_name}=={pinned_version}: {e}. Skipping for Airflow.")
            else:
                try:
                    package_hash = get_pypi_hash(package_name, pinned_version)
                    airflow_pinned_dependencies[package_name] = {"version": pinned_version, "hash": package_hash}
                except Exception as e:
                    logging.warning(f"Failed to fetch hash for {package_name}=={pinned_version}: {e}. Skipping for Airflow.")
        else:
            logging.warning(f"Failed to pin version for {package_name} with specifier '{version_specifier}'. It will not be included in Airflow overrides.")

    for dep_spec in airflow_core_dependencies:
        package_name, version_specifier = parse_dependency_specifier(dep_spec)
        if package_name in ["apache-airflow", "apache-airflow-core", "apache-airflow-task-sdk"] or package_name.startswith("apache-airflow-providers-"):
            continue

        pinned_version = resolve_version_from_pypi(package_name, version_specifier)
        if pinned_version:
            if package_name in GITHUB_PACKAGES:
                github_info = GITHUB_PACKAGES[package_name]
                try:
                    package_hash = get_github_hash(github_info["owner"], github_info["repo"], f"{github_info["tag_prefix"]}{pinned_version}")
                    airflow_core_pinned_dependencies[package_name] = {"version": pinned_version, "hash": package_hash}
                except Exception as e:
                    logging.warning(f"Failed to fetch GitHub hash for {package_name}=={pinned_version}: {e}. Skipping for Airflow Core.")
            else:
                try:
                    package_hash = get_pypi_hash(package_name, pinned_version)
                    airflow_core_pinned_dependencies[package_name] = {"version": pinned_version, "hash": package_hash}
                except Exception as e:
                    logging.warning(f"Failed to fetch hash for {package_name}=={pinned_version}: {e}. Skipping for Airflow Core.")

    output_airflow_nix_content = generate_nix_overrides(airflow_pinned_dependencies)
    output_airflow_core_nix_content = generate_nix_overrides(airflow_core_pinned_dependencies)

    with open("airflow-deps.nix", "w") as f:
        f.write(output_airflow_nix_content)
    logging.info("Generated airflow-deps.nix with pinned dependencies.")

    with open("airflow-core-deps.nix", "w") as f:
        f.write(output_airflow_core_nix_content)
    logging.info("Generated airflow-core-deps.nix with pinned dependencies.")

if __name__ == "__main__":
    main()
