let 

extraConfig = ''
'';

all_verbs = ["options" "head" "get" "post" "patch" "put" "delete"];


in rec {
  certdir = /opt/ekklesia/etc/certs;

  admins = [
    ["escaP" "escaP@piraten-oberpfalz.de"]
  ];
  managers = admins;
  db = {
    port = "5432";
    password = "pU04HaEB2MczCCscO";
  };
  logfile = "/var/log/ekklesia/ekklesia.production.log";
  allowedHosts = [
    "localhost"
    "127.0.0.1"
    "id.piratenpartei.ch"
    "id.partipirate.ch"
    "idapi.piratenpartei.ch"
  ];
  email = {
    subjectPrefix = "[televotia]";
    defaultFrom = "televotia@id.piratenpartei.ch";
    host = "localhost";
    useTls = true;
    defaultImap = {
      ca_certs = certdir + /ca-certificates.crt;
      certfile = certdir + /televotiamail.crt;
      keyfile = certdir + /televotiamail.key;
    };
    defaultSmtp = {
      host = "localhost";
      port = 587;
      ca_certs = certdir + /ca-certificates.crt;
      keyfile = certdir + /televotiamail.key;
      certfile = certdir + /televotiamail.crt;
    };
  };

  ssl = {
    basicAuth = {
      invitations = [ 
        [ "test" "invitations" "invitations" ] 
        [ "test_escap" "test_escap" "invitations" ] 
        [ "test_savvy" "test_savvy" "invitations" ] 
      ];
      members = [ 
        [ "test" "members" "members" ] 
        [ "test_escap" "test_escap" "members" ] 
        [ "test_savvy" "test_savvy" "members" ] 
      ];
    };
    clientLogin = {
      test = [ "test" ];
      portal = [ "portal" ];
    };
    certs = {
      test = certdir + /test.crt;
      test_escap = certdir + /televotia-test-escap.crt;
      test_savvy = certdir + /televotia-test-savvy.crt;
    };
  };

  shareClients = {
    portal = {
      portal = all_verbs;
    };
  };

  listClients = {
    portal = all_verbs;
  };
    
  apiGnupgKey = [ "televotia@id.piratenpartei.ch" "televotia" ];
  apiBackendKeys = {
    invitations = "invitations@id.piratenpartei.ch";
    members = "members@id.piratenpartei.ch";
  };
  
  # pyamqp://username:pass@host/virtual 
  brokerUrl = pyamqp://id:id@localhost/id;

  secretKey = "2u4SQvg5EdZxxA2fM6QT";
  mailhidePublic = "01olNgeIYYMbJlz6Ex-PVMlQ==";
  mailhidePrivate = "3da2729f0206e8611fffee918f19794e";
  recaptchaPublic = "key";
  recaptchaPrivate = "priv";
  inherit extraConfig;
}
