{customVarsPath ? ./custom_vars.nix, vars ? null }:

let
pkgs = import <nixpkgs> {};
lib = pkgs.lib;
mylib = scopedImport { inherit lib; } ./mylib.nix;
requirements = (import ../ekklesia/requirements/requirements.nix {}).packages;
ekklesia = import ../ekklesia {};
uwsgi = pkgs.uwsgi.override { plugins = [ "python3" ]; };
python = ekklesia.interpreter;
sitePackages = "lib/${python.libPrefix}/site-packages";
pythonpath = lib.concatMapStringsSep ":" (p: "${p}/${sitePackages}") (builtins.filter (x: lib.isDerivation x) (builtins.attrValues requirements) ++ [ ekklesia ]);
path = lib.concatMapStringsSep ":" (p: "${p}/bin") (ekklesia.propagatedNativeBuildInputs ++ [ekklesia]);
ekklesiaSitePackages = ekklesia + "/" + sitePackages;
_vars = if vars != null then vars 
  else lib.recursiveUpdate (import ./default_vars.nix) (scopedImport { inherit lib pkgs; } customVarsPath);

config = scopedImport { vars=_vars; inherit ekklesia ekklesiaSitePackages lib mylib; } ./settings_template.nix;
configfile = pkgs.writeText "ekklesia-settings.py" config;

startscript = pkgs.writeScript "start-ekklesia-uwsgi.sh" ''
  echo PYTHONPATH is: $PYTHONPATH
  echo PATH is: $PATH
  ${uwsgi}/bin/uwsgi \
    --http :8000 \
    --plugin python3 \
    --wsgi-file ${ekklesia}/lib/${python.libPrefix}/site-packages/identity/wsgi.py \
    "$@"
'';

in pkgs.stdenv.mkDerivation {
  name = "ekklesiaconf";
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
    ln -s ${ekklesia} $out/ekklesia
    cp ${configfile} $settings_pkg/settings.py

    wrapper_envvars="\
      --prefix PYTHONPATH : ${pythonpath}:$sitepac \
      --prefix DJANGO_CONFIGURATION : Production \
      --prefix DJANGO_SETTINGS_MODULE : nixekklesiaconfig.settings \
      --prefix PATH : ${path} \
      "

    wrapProgram $prog $wrapper_envvars
    makeWrapper ${ekklesia}/bin/ekklesia-manage.py $out/bin/ekklesia-manage.py $wrapper_envvars
    makeWrapper ${requirements.celery}/bin/celery $out/bin/ekklesia-celery.py $wrapper_envvars \
      --prefix CELERY_WORKER : yes
  '';
}
