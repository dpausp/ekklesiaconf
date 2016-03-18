let 
conv = rec {
  null = v: "None";
  string = v: ''"${v}"'';
  int = v: "${toString v}";
  path = v: string ( toString v );
  bool = v: if v == true then "True" else "False";
  lambda = v: throw "cannot convert lambda to Python literal!";
  list = v: "[" + ( lib.concatMapStringsSep ", " toPython v ) + "]";
  set = v: "{" + ( lib.concatStringsSep ", " ( lib.mapAttrsToList ( name: value: "${string name}: ${toPython value}" ) v ) ) + "}";
};

matchType = cases: v: ( lib.getAttr ( builtins.typeOf v ) cases ) v;
toPython = v: matchType conv v;

in {
  inherit toPython;
}

