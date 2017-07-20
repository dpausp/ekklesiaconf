{customVarsPath ? ./custom_vars.nix, vars ? null }:

let
pkgs = import <nixpkgs> {};
lib = pkgs.lib;
mylib = scopedImport { inherit lib; } ./mylib.nix;
ekklesia = import ../ekklesia {};
deps = ekklesia.deps;
python = ekklesia.python;
uwsgi = pkgs.callPackage ./uwsgi.nix { python3 = python; plugins = [ "python3" ]; };
sitePackages = "lib/${python.libPrefix}/site-packages";
pythonpath = lib.concatMapStringsSep ":" (p: "${p}/${sitePackages}") (builtins.filter (x: lib.isDerivation x) (builtins.attrValues deps) ++ [ ekklesia ]);
path = lib.concatMapStringsSep ":" (p: "${p}/bin") (ekklesia.propagatedNativeBuildInputs ++ [ekklesia]);
ekklesiaSitePackages = ekklesia + "/" + sitePackages;
_vars = if vars != null then vars 
  else lib.recursiveUpdate (import ./default_vars.nix) (scopedImport { inherit lib pkgs; } customVarsPath);

config = scopedImport { vars=_vars; inherit ekklesia ekklesiaSitePackages lib mylib; } ./settings_template.nix;
configfile = pkgs.writeText "ekklesia-settings.py" config;

startscript = with _vars; with lib; pkgs.writeScript "start-ekklesia-uwsgi.sh" ''
  echo PYTHONPATH is: $PYTHONPATH
  echo PATH is: $PATH
  ${uwsgi}/bin/uwsgi \
    --http ${uwsgi_http_address}:${toString uwsgi_http_port} \
    --plugin python3 \
    --wsgi-file ${ekklesia}/lib/${python.libPrefix}/site-packages/identity/wsgi.py \
    "$@"
'';

managescript = pkgs.writeScript "ekklesia-manage" ''
  echo PYTHONPATH is: $PYTHONPATH
  echo PATH is: $PATH
  python3 ${ekklesia}/lib/python3.6/site-packages/manage.py "$@"
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
    makeWrapper ${python}/bin/python3 $out/bin/python3 $wrapper_envvars
    makeWrapper ${managescript} $out/bin/ekklesia-manage $wrapper_envvars
    makeWrapper ${deps.celery}/bin/celery $out/bin/ekklesia-celery.py $wrapper_envvars \
      --prefix CELERY_WORKER : yes
  '';
}
