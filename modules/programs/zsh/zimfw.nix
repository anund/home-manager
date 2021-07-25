{ config, pkgs, lib, ... }:
with lib;
let
  zim = pkgs.callPackage ./default.nix {};

  cfg = config.programs.zsh.zimfw;

  zimfwModule = types.submodule {
    options = {
      enable = mkEnableOption "zimfw";
      zshrc = mkOption {
        type = types.str;
        default = (builtins.readFile "${zim}/share/zsh-zim/zshrc");
        description = "Contents to include in zshrc. Must include TODO";
      };
      zModules = mkOption {
        type = types.listOf types.str;
        default = [
          "environment"
          "git"
          "input"
          "termtitle"
          "utility"
          "duration-info"
          "git-info"
          "asciiship"
          "zsh-users/zsh-completions"
          "completion"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-syntax-highlighting"
          "zsh-users/zsh-history-substring-search"
        ];
        description =
          "Set the Zim modules to load (browse modules). The order matters.";
      };
    };
  };

  relToDotDir = file:
    (optionalString (config.programs.zsh.dotDir != null)
      (config.programs.zsh.dotDir + "/")) + file;

  zimHome = "${config.home.homeDirectory}/${relToDotDir ".zim"}";
  zHome = "${config.home.homeDirectory}/" +
    "${optionalString (config.programs.zsh.dotDir != null) (config.programs.zsh.dotDir + "/")}";

  zimrc = zModule: ''
    # Auto generated
    ${concatStringsSep "\n" (map (x: "zmodule ${x}") zModule)}
  '';

  # note changes to this function will _not_ run unless zimrc or zshrc are changed
  zimUpdate = file: ''
    echo ${file} changed updating zim modules
    $DRY_RUN_CMD export ZIM_HOME=${zimHome}
    $DRY_RUN_CMD ${pkgs.zsh}/bin/zsh ${zimHome}/zimfw.zsh install -q
    $DRY_RUN_CMD ${pkgs.zsh}/bin/zsh ${zimHome}/zimfw.zsh uninstall -q
    $DRY_RUN_CMD unset ZIM_HOME
    echo Completed zim modules update
  '';
in
{
  options = {
    programs.zsh = {
      zimfw = mkOption {
        type = zimfwModule;
        default = { };
        description = "Options to configure zimfw.";
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
  {
    home.file."${relToDotDir ".zim/zimfw.zsh"}".source = "${zim}/share/zsh-zim/.zim/zimfw.zsh";
    home.file."${relToDotDir ".zimrc"}" = {
      text = "${zimrc cfg.zModules}";
      onChange = zimUpdate ".zimrc";
    };
    home.file."${relToDotDir ".zshrc"}".onChange = zimUpdate ".zshrc";
    home.packages = [ zim ];
    programs.zsh.sessionVariables = {
      ZIM_HOME = "${zimHome}";
    };
    programs.zsh = {
      envExtra = ''
        ${pkgs.lib.readFile "${zim}/share/zsh-zim/zshenv"}
      '';
      loginExtra = ''
        ${pkgs.lib.readFile "${zim}/share/zsh-zim/zlogin"}
      '';
    };
  }]);
}
