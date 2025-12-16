inputs: _: prev:
let
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = prev.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
    };
  };
in
{
  unstable = unstablePkgs;
}
