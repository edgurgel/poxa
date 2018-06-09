[
  extends: [],
  import: [],
  mappings: [
    "poxa.port": [
      commented: false,
      datatype: :integer,
      default: 8080,
      doc: "HTTP Port",
      hidden: false,
      env_var: "PORT",
      to: "poxa.port"
    ],
    "poxa.app_key": [
      commented: false,
      datatype: :binary,
      default: "app_key",
      doc: "Pusher app key",
      hidden: false,
      env_var: "POXA_APP_KEY",
      to: "poxa.app_key"
    ],
    "poxa.app_secret": [
      commented: false,
      datatype: :binary,
      default: "secret",
      doc: "Pusher secret",
      hidden: false,
      env_var: "POXA_SECRET",
      to: "poxa.app_secret"
    ],
    "poxa.app_id": [
      commented: false,
      datatype: :binary,
      default: "app_id",
      doc: "Pusher app id",
      hidden: false,
      env_var: "POXA_APP_ID",
      to: "poxa.app_id"
    ],
    "poxa.registry_adapter": [
      commented: false,
      datatype: :binary,
      default: "gproc",
      doc: "Registry adapter",
      hidden: false,
      env_var: "POXA_REGISTRY_ADAPTER",
      to: "poxa.registry_adapter"
    ],
    "poxa.web_hook": [
      commented: false,
      datatype: :binary,
      doc: "Web hook endpoint",
      hidden: false,
      default: "",
      env_var: "WEB_HOOK",
      to: "poxa.web_hook"
    ],
    "poxa.ssl.enabled": [
      doc: "HTTPS switch",
      to: "poxa.ssl.enabled",
      datatype: :boolean,
      env_var: "POXA_SSL",
      default: false,
    ],
    "poxa.ssl.port": [
      doc: "HTTPS port",
      to: "poxa.ssl.port",
      env_var: "SSL_PORT",
      default: 8443,
      datatype: :integer,
    ],
    "poxa.ssl.cacertfile": [
      doc: "PEM-encoded CA certificate path",
      to: "poxa.ssl.cacertfile",
      env_var: "SSL_CACERTFILE",
      default: "",
      datatype: :binary,
    ],
    "poxa.ssl.certfile": [
      doc: "Path to user certificate",
      to: "poxa.ssl.certfile",
      env_var: "SSL_CERTFILE",
      default: "",
      datatype: :binary,
    ],
    "poxa.ssl.keyfile": [
      doc: "Path to the file containing the user's private PEM-encoded key",
      to: "poxa.ssl.keyfile",
      env_var: "SSL_KEYFILE",
      default: "",
      datatype: :binary,
    ],
    "poxa.payload_limit": [
      doc: "Payload limit for a message",
      to: "poxa.payload_limit",
      env_var: "PAYLOAD_LIMIT",
      default: 10_000,
      datatype: :integer,
    ],
  ],
  transforms: [],
  validators: []
]
