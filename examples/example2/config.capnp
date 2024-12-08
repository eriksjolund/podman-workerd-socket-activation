using Workerd = import "/workerd/workerd.capnp";

const config :Workerd.Config = (
  services = [
    (name = "main", worker = .mainWorker),
    (name = "any", network = .myNetwork),
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
  compatibilityDate = "2024-12-01",
  globalOutbound = "any",
  modules = [
    (name = "worker", esModule = embed "fetch.js"),
    (name = "library", esModule = embed "library.js"),
  ],
);

const myNetwork :Workerd.Network = (
  allow = ["0.0.0.0/0"],
  deny = []
);
