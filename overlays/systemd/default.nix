finalPkgs: prevPkgs: {
  # Adabted from https://github.com/yunfachi/NixOwOS/pull/4/changes
  suwustemd = prevPkgs.systemd.overrideAttrs (
    finalAttrs: prevAttrs: {
      patches = (prevAttrs.patches or [ ]) ++ [
        ./nixowos_support.patch
      ];
    }
  );
}
