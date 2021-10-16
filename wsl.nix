{
  nix.settings = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "auto-allocate-uids"
      "cgroups"
      "fetch-closure"
      "dynamic-derivations"
      "no-url-literals"
    ];
    trusted-users = ["root" "@wheel"];
    auto-allocate-uids = true;
    use-cgroups = true;
  };
  nixpkgs.hostPlatform = "x86_64-linux";

  environment.localBinInPath = true;

  services = {
    openssh = {
      enable = true;
      startWhenNeeded = true;
      ports = [22 2222];
    };
  };
  programs = {
    nano.enable = false;
    zsh.enable = true;
    git.enable = true;
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    sway.enable = true;
  };
}
