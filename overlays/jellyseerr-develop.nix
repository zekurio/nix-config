inputs: final: prev: let
  nodejs = prev.nodejs_22;
  pnpm = prev.pnpm_10.override { inherit nodejs; };
in {
  jellyseerr = prev.jellyseerr.overrideAttrs (oldAttrs: 
    let
      src = prev.fetchFromGitHub {
        owner = "seerr-team";
        repo = "seerr";
        rev = "develop";
        hash = "sha256-/RdLL3EhcAXxSDdZwhsGqW+Uge6Mbj9OSCL/qj2OTlc="; # Got from build error
      };
    in {
      version = "develop";
      inherit src;
      
      # Override pnpm to use version 10
      pnpmDeps = pnpm.fetchDeps {
        inherit (oldAttrs) pname;
        version = "develop";
        inherit src;
        fetcherVersion = 1;
        hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="; # Placeholder, will update
      };
      
      # Update nativeBuildInputs to use the new pnpm
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pnpm.configHook ];
    });
}