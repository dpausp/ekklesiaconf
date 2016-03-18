let
pkgs = import <nixpkgs> {};
lib = pkgs.lib;
mylib = scopedImport { inherit lib; } ./mylib.nix;
ekklesia = import ../ekklesia/default.nix {};
uwsgi = pkgs.uwsgi.override { plugins = ["python2"]; };
python = pkgs.pythonPackages.python;
sitePackages = "lib/${python.libPrefix}/site-packages";
pythonpath = lib.concatMapStringsSep ":" (p: "${p}/${sitePackages}") (ekklesia.propagatedNativeBuildInputs ++ [ekklesia]);
path = lib.concatMapStringsSep ":" (p: "${p}/bin") (ekklesia.propagatedNativeBuildInputs ++ [ekklesia]);
ekklesiaSitePackages = ekklesia + "/" + sitePackages;
vars = lib.recursiveUpdate (import ./default_vars.nix) (import ./custom_vars.nix);

config = scopedImport { inherit vars ekklesia ekklesiaSitePackages lib mylib; } ./settings_template.nix;
configfile = pkgs.writeText "ekklesia-settings.py" config;

startscript = pkgs.writeScript "start-ekklesia-uwsgi.sh" ''
  echo PYTHONPATH is: $PYTHONPATH
  echo PATH is: $PATH
  ${uwsgi}/bin/uwsgi \
    --http :8000 \
    --plugin python2 \
    --wsgi-file ${ekklesia}/lib/${python.libPrefix}/site-packages/identity/wsgi.py \
    "$@"
'';

in pkgs.stdenv.mkDerivation {
  name = "myekklesiaconf";
  src = lib.cleanSource ./.;
  dontBuild = true;
  buildInputs = with pkgs; [ makeWrapper ];
  installPhase = ''
    sitepac=$out/${sitePackages}
    settings_pkg=$sitepac/nixekklesiaconfig
    bin=$out/bin
    prog=$bin/start-ekklesia-uwsgi

    mkdir -p $bin $sitepac $settings_pkg
    touch $settings_pkg/__init__.py
    ln -s ${startscript} $prog
    cp ${configfile} $settings_pkg/settings.py

    wrapper_envvars="\
      --prefix PYTHONPATH : ${pythonpath}:$sitepac \
      --prefix DJANGO_CONFIGURATION : Production \
      --prefix DJANGO_SETTINGS_MODULE : nixekklesiaconfig.settings \
      --prefix PATH : ${path} \
      "

    wrapProgram $prog $wrapper_envvars
    makeWrapper ${ekklesia}/bin/ekklesia-manage.py $out/bin/ekklesia-manage.py $wrapper_envvars
  '';
}
