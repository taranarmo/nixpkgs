{
  makeSetupHook,
  writeText,
  lfortran,
  test-drive,
  toml-f,
}:

# Build toml-f and its test-drive dependency with LFortran in place of
# gfortran, and run toml-f's test suite.
let
  # Stands in for gfortran: like cc-wrapper's fortran-hook.sh, point `FC` at
  # the compiler. Meson doesn't know LFortran, so these builds use CMake.
  lfortranAsFC =
    makeSetupHook
      {
        name = "lfortran-as-fc";
        propagatedBuildInputs = [ lfortran ];
      }
      (
        writeText "lfortran-as-fc-hook.sh" ''
          export FC=lfortran
          # Fortran 2003 reallocation on assignment is opt-in in LFortran.
          export FFLAGS="--realloc-lhs-arrays"
        ''
      );

  test-drive' = test-drive.override {
    gfortran = lfortranAsFC;
    buildType = "cmake";
  };
in
(toml-f.override {
  gfortran = lfortranAsFC;
  buildType = "cmake";
  test-drive = test-drive';
}).overrideAttrs
  (old: {
    pname = "${old.pname}-lfortran";
    doCheck = true;
  })
