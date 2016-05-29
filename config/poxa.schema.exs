[
  mappings: [
    "poxa.port": [
      doc: "HTTP port",
      to: "poxa.port",
      commented: false,
      datatype: :integer,
      default: 8080
    ],
    "poxa.app_key": [
      doc: "Pusher app key",
      to: "poxa.app_key",
      commented: false,
      datatype: :binary,
      default: "app_key"
    ],
    "poxa.app_secret": [
      doc: "Pusher secret",
      to: "poxa.app_secret",
      commented: false,
      datatype: :binary,
      default: "secret"
    ],
    "poxa.app_id": [
      doc: "Pusher app id",
      to: "poxa.app_id",
      commented: false,
      datatype: :binary,
      default: "app_id"
    ],
    "poxa.registry_adapter": [
      commented: false,
      datatype: :binary,
      default: "gproc",
      doc: "Registry adapter",
      hidden: false,
      to: "poxa.registry_adapter"
    ],
    "poxa.web_hook": [
      commented: true,
      datatype: :atom,
      doc: "Web hook endpoint",
      hidden: false,
      to: "poxa.web_hook"
     ],
    "poxa.ssl.enabled": [
      doc: "HTTPS switch",
      to: "poxa.ssl.enabled",
      datatype: :boolean,
      default: false,
    ],
    "poxa.ssl.port": [
      doc: "HTTPS port",
      to: "poxa.ssl.port",
      datatype: :integer,
    ],
    "poxa.ssl.cacertfile": [
      doc: "PEM-encoded CA certificate path",
      to: "poxa.ssl.cacertfile",
      datatype: :binary,
    ],
    "poxa.ssl.certfile": [
      doc: "Path to user certificate",
      to: "poxa.ssl.certfile",
      datatype: :binary,
    ],
    "poxa.ssl.keyfile": [
      doc: "Path to the file containing the user's private PEM-encoded key",
      to: "poxa.ssl.keyfile",
      datatype: :binary,
    ]
  ],
  translations: [
  ]
]
