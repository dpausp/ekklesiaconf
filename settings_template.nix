let 
py = mylib.toPython;
optional = settings_key: v: 
  let path = lib.splitString "." v; in
  if lib.hasAttrByPath path vars then "${settings_key} = ${mylib.toPython (lib.attrByPath path "" vars)}" else "";
in
with vars;
(import ./default_settings.nix) +
''

### customized part

import os.path
settings_path = os.path.abspath(__file__)
print("loading config from file {}, (real: {})".format(settings_path, os.path.realpath(settings_path)))


def common(production=False, admin=False, site=0):
    class Common(defaults(production, admin, site)):
        
        ### Nix-specific setting overrides depending on nix store location of ekklesia

        TOP_ROOT = "${ekklesia}"
        SITE_ROOT = "${ekklesia}/identity"
        STATIC_ROOT = "${ekklesia}/share/www/static.prod"
        TEMPLATE_DIRS = ("${ekklesia}/share/templates",)
        LOCALE_PATHS= ("${ekklesia}/share/locale",)

        ### settings configurable by Nix

        ADMINS = ${py admins}
        MANAGERS = ${py managers}
        ALLOWED_HOSTS = ${py allowedHosts}
        SECRET_KEY = ${py secretKey}
        DATABASES = {
            'default': {'ENGINE': 'django.db.backends.postgresql_psycopg2',
                        'PORT': '${db.port}',
                        'HOST': '${db.host}',
                        'NAME': '${db.name}',
                        'PASSWORD': '${db.password}',
                        'USER': '${db.user}'
            }
        }

        DEFAULT_FROM_EMAIL = ${py email.defaultFrom}
        EMAIL_SUBJECT_PREFIX = ${py email.subjectPrefix}

        ${optional "EMAIL_HOST" "email.host"}
        ${optional "EMAIL_PORT" "email.port"}
        ${optional "EMAIL_HOST_USER" "email.hostUser"}
        ${optional "EMAIL_HOST_PASSWORD" "email.hostPassword"}
        ${optional "EMAIL_USE_TLS" "email.useTls"}

        ${optional "EMAIL_DEFAULT_IMAP" "email.defaultImap"}
        ${optional "EMAIL_DEFAULT_SMTP" "email.defaultSmtp"}

        RECAPTCHA_PUBLIC_KEY = ${py recaptchaPublic}
        RECAPTCHA_PRIVATE_KEY = ${py recaptchaPrivate}

        API_GNUPG_KEY = ${py apiGnupgKey}

        # gnupg keys backend:(id,passphrase) for verfication and encryption
        API_BACKEND_KEYS = ${py apiBackendKeys}
        SSL_CERTS = {
            ${lib.concatStringsSep ", " ( lib.mapAttrsToList ( k: v: ''open("${v}").read(): "${k}"'' ) ssl.certs )}
        }
        SSL_BASIC_AUTH = ${py ssl.basicAuth}
        SSL_CLIENT_LOGIN = ${py ssl.clientLogin}
        SHARE_CLIENTS = ${py shareClients}
        LISTS_CLIENTS = ${py listClients}

        BROKER_URL = ${py brokerUrl}

        EMAIL_BACKEND = ${py (
          if email.defaultSmtp != null then
            "django.core.mail.backends.smtp.EmailBackend"
          else
            "django.core.mail.backends.console.EmailBackend")}

        PASSWORD_HASHERS = ('django_scrypt.hashers.ScryptPasswordHasher', )
        INTERNAL_IPS = ("127.0.0.1", )

        ### TODO

        EMAIL_IDS = {'idserver': {'email': '${senderEmail}'}}

        SHARE_PUSH = {'portal': ['https://portal.local/pushshare/']}
        USE_CELERY = True

        EMAIL_REGISTER_ID = 'register'

        EMAIL_CLIENTS = {'debug': {'idserver': [True, True, True]},
                         'portal-local': {'idserver': [True, None, True],
                                          'voting': [True, True, True]},
                         'votingModule': {'voting': [True, True, True]},
                         'vvvote': {'voting': [True, True, False]},
                         'vvvote2': {'voting': [True, True, False]}}

        ### CONSTANTS

        EMAIL_GPG_IMPORT_HOME = None
        EMAIL_GPG_HOME = None
        EMAIL_INDEP_CRYPTO = False
        #EMAIL_QUEUE = 'crypto'
        EMAIL_QUEUE = 'mail'
        EMAIL_TEMPLATES = {
            'register_confirm': {
                'body': u'Bitte best\xe4tige deine Registrierung, indem du entweder auf {url}={code} gehst oder den folgenden Code auf {url} eingibst: {code}',
                'subject': 'Registrierung'},
            'single_vote_confirmation': {
                'body': u'Hallo, du hast am {time} f\xfcr {abstimmung} wie folgt abgestimmt: {options} Bitte bewahre diesen Nachweis sicher auf.',
                'subject': u'Best\xe4tigung deiner Stimmabgabe'}}

        STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
        # XXX: doesn't work with bootstrap3, why?
        CRISPY_TEMPLATE_PACK = 'bootstrap4'

        CACHES = {
            "default": {
                "BACKEND": "django_redis.cache.RedisCache",
                "LOCATION": "redis://localhost:6379/1",
                "OPTIONS": {
                    "CLIENT_CLASS": "django_redis.client.DefaultClient",
                }
            }
        }

    ### extra

    ${extraConfig}

    return Common


class Debug(common(production=False, admin=True, site=1)):
    pass


class Production(common(production=True, admin=True, site=1)):
    ${if debugInProduction then "DEBUG = True" else "pass"}


class ProductionAPI(common(production=True,admin=False,site=2)):
    ${if debugInProduction then "DEBUG = True" else "pass"}
''
