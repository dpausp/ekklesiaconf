{
  db = {
    name = "identity";
    host = "127.0.0.1";
    port = "5432";
    user = "identity";
    password = "identity";
  };
  debugInProduction = false;
  logfile = "/var/log/ekklesia/identity.production.log";
  allowedHosts = [
    "localhost"
    "127.0.0.1"
  ];
  email = {
    subjectPrefix = "[identity]";
    defaultFrom = "localhost";
    useTls = true;
  };

  apiGnupgKey = null;
  apiBackendKeys = {};
  senderEmail = "identity@example.com";
  uwsgi_http_address = "127.0.0.1";
  uwsgi_http_port = 8000;
}
