let 

nixpkgs = import <nixpkgs> {};
lib = nixpkgs.lib;
mylib = scopedImport { inherit lib; } ./mylib.nix;

in 
with mylib;
assert toPython 5 == "5";
assert toPython "5" == ''"5"'';
assert toPython null == "None";
assert toPython true == "True";
assert toPython false == "False";
assert toPython /dev/shm == ''"/dev/shm"'';
assert toPython [ 1 [ 2 3 ] 4 ]  == "[1, [2, 3], 4]";
assert toPython { test = "5"; blah = 42; } == ''{"blah": 42, "test": "5"}'';
{}
