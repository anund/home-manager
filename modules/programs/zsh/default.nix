{ stdenv
, fetchFromGitHub
, zsh
, git
, coreutils
, curl
, wget
, lib
}:

stdenv.mkDerivation rec {
  pname = "zsh-zim";
  version = "1.4.3";

  srcs = [
    (fetchFromGitHub {
      owner = "zimfw";
      repo = "zimfw";
      rev = "v${version}";
      sha256 = "0x8qv062vdlq83mv2mxhspfyyk42n4p03gndyb41k7yz4n47bnhx";
      name = "zimfw";
    })
    (fetchFromGitHub {
      owner = "zimfw";
      repo = "install";
      rev = "3c346360e73609f0fc2829992f79a771fc731db7";
      sha256 = "09dm2aiphmv6fyl2d6fg0b0f2gbavqk158cf0qlqcqbfxql29k41";
      name = "install";
    })
  ];

  sourceRoot = ".";

  buildInputs = [ zsh git ];

  buildPhase = ''
    # setup zdotdir
    mkdir -p $out/share/zsh-zim
    #rcfiles=('zshenv' 'zshrc' 'zlogin' 'zimrc')
    cp install/src/templates/zshenv $out/share/zsh-zim/zshenv
    cp install/src/templates/zlogin $out/share/zsh-zim/zlogin

  '';

  installPhase = ''
    # setup zdotdir
    mkdir -p $out/share/zsh-zim

    rcfiles=('zshenv' 'zshrc' 'zlogin' 'zimrc')
    for entry in "''${rcfiles[@]}"; do
      cp "install/src/templates/''${entry}" $out/share/zsh-zim/"''${entry}"
    done

    # setup zim home
    mkdir -p $out/share/zsh-zim/.zim
    cp zimfw/zimfw.zsh $out/share/zsh-zim/.zim/zimfw.zsh

    substituteInPlace $out/share/zsh-zim/.zim/zimfw.zsh \
      --replace 'command git' 'command ${git}/bin/git' \
      --replace 'command rm' 'command ${coreutils}/bin/rm' \
      --replace 'command mv' 'command ${coreutils}/bin/mv' \
      --replace 'command cksum' 'command ${coreutils}/bin/cksum' \
      --replace 'command uname' 'command ${coreutils}/bin/uname' \
      --replace 'command curl' 'command ${curl}/bin/curl'
  '';

  meta = with lib; {
    description = "Zim is a Zsh configuration framework with blazing speed and modular extensions.";
    longDescription = ''
      Zim is very easy to customize, and comes with a rich
      set of modules and features without compromising on
      speed or functionality!
    '';
    homepage = "https://github.com/zimfw/zimfw";
    license = licenses.mit;
    maintainers = with maintainers; [ anund ];
    platforms = platforms.unix;
  };
}
