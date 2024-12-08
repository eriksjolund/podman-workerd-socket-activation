# podman-workerd-socket-activation

This demo shows how to run a socket-activated [workerd](https://github.com/cloudflare/workerd/) container with Podman
so that _worked_ acts as an HTTP reverse proxy.
To learn about _worked_, see Cloudflare [blog post](https://blog.cloudflare.com/workerd-open-source-workers-runtime/).
See also the tutorials
[Podman socket activation](https://github.com/containers/podman/blob/main/docs/tutorials/socket_activation.md) and
[podman-nginx-socket-activation](https://github.com/eriksjolund/podman-nginx-socket-activation). 

Overview of the examples

| Example | Type of service | Ports | rootful/rootless podman | ip_unprivileged_port_start | Comment |
| --      | --              |    -- | --                      |                         -- | --      |
| [Example 1](examples/example1) | systemd user service | 80 | rootless podman | 80 | using `:Workerd.ExternalServer` |
| [Example 2](examples/example2) | systemd user service | 80 | rootless podman | 80 | using `globalOutbound` and `:Workerd.Network` to allow proxying to any backend server on the podman internal custom network _mynet_. |

### Introduction

While workerd can create sockets by itself, there are security and performance advantages of using
a service manager, such as systemd, for creating the sockets.
There is no need for workerd to create listening sockets as long as workerd inherits those sockets
from its parent process. This technique, commonly named _socket activation_, is
supported for example when workerd is running as a systemd service. Optionally Podman can start
workerd in the systemd service in case you want to run workerd inside a container.

Using _socket activation_ allows you to run workerd with fewer privileges
because workerd would not need the privilege to create a socket.

For example if Podman is running workerd as a static web server, then it is possible
to enable the Podman option `--network=none` which improves security.

Using _socket activation_ improves network performance when workerd is run by rootless Podman in a systemd service.
When using rootless Podman, network traffic is normally passed through Slirp4netns or Pasta.
This comes with a performance penalty. Fortunately, communication over the socket-activated
socket does not pass through Slirp4netns or Pasta so it has the same performance characteristics
as the normal network on the host.

The source IP address in TCP connections is preserved when using socket activation.
This can otherwise be a problem when using rootless Podman with Pasta.
Source IP addresses are not preserved in TCP connections from ports that were published the
conventional way, that is with `--publish`, if the container is running in a custom network
by rootless Podman with Pasta.

### Advantages of using rootless Podman with socket activation

See https://github.com/eriksjolund/podman-nginx-socket-activation?tab=readme-ov-file#advantages-of-using-rootless-podman-with-socket-activation
