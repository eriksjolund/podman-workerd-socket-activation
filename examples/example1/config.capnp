using Workerd = import "/workerd/workerd.capnp";

const config :Workerd.Config = (
  services = [
    (name = "main", worker = .mainWorker),
    (name = "whoamiServer", external = .whoamiServer),
  ],
  sockets = [
    ( name = "mySocket",
      http = (
    ),
    service = "main"
    ),
  ]
);

const mainWorker :Workerd.Worker = (
  bindings = [
    (name = "whoami_binding", service = "whoamiServer")
  ],
  compatibilityDate = "2024-12-01",
  modules = [
    (name = "worker", esModule = embed "fetch.js"),
    (name = "library", esModule = embed "library.js"),
  ],
);

const whoamiServer :Workerd.ExternalServer = (
  address = "whoami.example.com:80",
  http = ()
);
