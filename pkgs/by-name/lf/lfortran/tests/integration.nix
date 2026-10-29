{
  stdenv,
  cmake,
  ninja,
  python3,
  lfortran,
}:

# Upstream's integration test suite: several thousand Fortran programs built
# and run with the LLVM backend.
stdenv.mkDerivation {
  name = "${lfortran.pname}-test-integration";
  inherit (lfortran) src;

  nativeBuildInputs = [
    lfortran
    cmake
    ninja
    python3
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    cd integration_tests
    patchShebangs .
    python run_tests.py -b llvm --ninja -j $NIX_BUILD_CORES \
      --build-dir "$TMPDIR/build" --compiler-dir ${lfortran}/bin

    runHook postBuild
  '';

  installPhase = ''
    touch $out
  '';

  requiredSystemFeatures = [ "big-parallel" ];

  # Upstream CI doesn't cover aarch64-linux. With 0.68.0 about 40 of 5400
  # tests fail there, mostly real(16)/long double ones that crash.
  meta.badPlatforms = [ "aarch64-linux" ];
}
