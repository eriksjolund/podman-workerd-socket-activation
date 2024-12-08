return to [main page](../..)

## Example example-nsenter

> [!NOTE]
> Not much has been written on the internet about
> using `nsenter` to run a command in the network
> namespace of rootless Podman,
> As of now consider this example a bit experimental.
> There is a discussion topic in the Podman Github project
> https://github.com/containers/podman/discussions/24626

> [!NOTE]
> Currently the _whoami_ container has its IP address hard-coded in.
> Maybe it's possible to look up that IP address
> by querying the aardvark internal DNS server?

_example-nsenter_ is similar to [_Example 1_](../example1) but here workerd is not run by Podman.
Instead the executable `/usr/local/bin/workerd` (from the host file system) is
running in a systemd system service with a `User=` directive.  `nsenter` executes `workerd`
in the network namespace of rootless Podman.

Note, even though workerd is running rootless, it is possible to use the default setting
for _ip_unprivileged_port_start_.

```
$ cat /proc/sys/net/ipv4/ip_unprivileged_port_start
1024
```

This is possible because the service is a systemd system service with a `User=` directive.
The most interesting part of the file _workerd.service_ is

```
User=test
ExecStart=bash -c "cd /var/srv/workerd && exec nsenter \
   --preserve-credentials \
   --net=/proc/$(cat $XDG_RUNTIME_DIR/containers/networks/aardvark-dns/aardvark.pid)/ns/net \
   --user=/proc/$(cat $XDG_RUNTIME_DIR/libpod/tmp/pause.pid)/ns/user \
   --mount=/proc/$(cat $XDG_RUNTIME_DIR/libpod/tmp/pause.pid)/ns/mnt \
   /usr/local/bin/workerd serve --verbose --socket-fd mySocket=3 /var/srv/workerd/config.capnp"
```

Diagram:

``` mermaid
graph TB

    a1[curl] -.->a2["/usr/local/bin/workerd (from the host file system)"]
    a2 -->|"for http&colon;//whoami.example.com"| a4["whoami container"]
```

Set up a systemd system service _workerd.service_ with the systemd configuration `User=test` that
runs `/usr/local/bin/workerd` from the host file system.
Workerd is acting as an HTTP reverse proxy that forwards requests for
https://whoami.example.com to a _whoami_ container.
Configure _socket activation_ for the port 80/TCP.

This example uses these files

* [../../examples/example1/mynet.network](../../examples/example1/mynet.network)
* [../../examples/example1/whoami.container](../../examples/example1/whoami.container)
* [../../examples/example1/config.capnp](../../examples/example1/config.capnp)
* [../../examples/example1/fetch.js](../../examples/example1/fetch.js)
* [../../examples/example1/library.js](../../examples/example1/library.js)
* [./workerd.socket](workerd.socket)
* [./workerd.service](workerd.service)

### Install /usr/local/bin/workerd on the host

Download the workerd executable from https://github.com/cloudflare/workerd/releases
and install the file to the path _/usr/local/bin/workerd_

<details>
<summary>Click me</summary>

1. Set shell variable to the latest workerd release
   ```
   version=$(curl -Ls https://api.github.com/repos/cloudflare/workerd/releases/latest | jq -r .tag_name)
   ```
   (See also https://github.com/cloudflare/workerd/releases)
1. Download either for _amd64_
   ```
   curl -LO https://github.com/cloudflare/workerd/releases/download/${version}/workerd-linux-64.gz
   ```
   or for _arm64_
   ```
   curl -L -o workerd.gz https://github.com/cloudflare/workerd/releases/download/${version}/workerd-linux-arm64.gz
   ```
1. Uncompress
   ```
   gunzip workerd.gz
   ```
1. Install the workerd executable to _/usr/local/bin/workerd_
   ```
   sudo install --mode 755 --owner root:root $PWD/workerd /usr/local/bin/
   ```

</details>


### Set up quadlets and systemd services

1. Create a test user
   ```
   sudo useradd test
   ```
1. Give sudo permissions to the user _test_
   ```
   sudo usermod -aG sudo test
   ```
   (The user _test_ does not require any sudo permissions for this
   example to work but having them simplifies how the documentation can
   be written)
1. Open a shell for user _test_
   ```
   sudo machinectl shell --uid=test
   ```
1. Optional step: enable lingering to avoid services from being stopped when
   the user _test_ logs out.
   ```
   loginctl enable-linger test
   ```
1. Create directories
   ```
   mkdir -p ~/.config/systemd/user
   mkdir -p ~/.config/containers/systemd
   ```
1. Pull the _whoami_ container image
   ```
   podman pull docker.io/traefik/whoami
   ```
1. Clone git repo
   ```
   git clone https://github.com/eriksjolund/podman-workerd-socket-activation.git
   ```
1. Change directory
   ```
   cd podman-workerd-socket-activation/examples.under-development/example-nsenter
   ```
1. Install the container unit file
   ```
   cp ../../examples/example1/whoami.container \
      ~/.config/containers/systemd/
   ```
1. Install the network unit file
   ```
   cp ../../examples/example1/mynet.net \
      ~/.config/containers/systemd/
   ```
1. Reload the systemd user manager
   ```
   systemctl --user daemon-reload
   ```
1. Start the _whoami_ container
   ```
   systemctl --user start whoami.service
   ```
1. Create directory
   ```
   sudo mkdir -p /var/srv/workerd
   ```
1. Install the file [_config.capnp_](../../examples/example1/config.capnp)
   ```
   sudo cp $PWD/../../examples/example1/config.capnp \
      /var/srv/workerd/
   ```
1. Install the file [_fetch.js_](../../examples/example1/fetch.js)
   ```
   sudo cp $PWD/../../examples/example1/fetch.js \
      /var/srv/workerd/
   ```
1. Install the file [_library.js_](../../examples/example1/library.js)
   ```
   sudo cp $PWD/../../examples/example1/library.js \
      /var/srv/workerd/
   ```
1. Show the IP address of the _whoami_ container
   ```
   podman container inspect whoami.example.com | jq -r '.[] | .NetworkSettings.Networks.mynet.IPAddress'
   ```
1. Edit _/var/srv/srv/workerd/config.capnp_ so that _whoami.example.com_ is replaced with the
   the IP address of the _whoami_ container.
1. Install the service file
   ```
   sudo cp $PWD/workerd.service \
      /etc/systemd/system/
   ```
1. Install the socket unit file
   ```
   sudo cp $PWD/workerd.socket \
      /etc/systemd/system/
   ```
1. Reload the systemd user manager
   ```
   systemctl daemon-reload
   ```
1. Start the workerd socket
   ```
   systemctl start workerd.socket
   ```
1. Download the URL __https://whoami.example.com__ and see that the request is
   proxied to the container _whoami.example.com_.
   Resolve _whoami.example.com_ to _127.0.0.1_ so that curl connects to localhost.
   ```
   curl -s --resolve whoami.example.com:80:127.0.0.1 \
     http://whoami.example.com | grep X-Forwarded
   ```
   The following output is printed
   ```
   X-Forwarded-For: 127.0.0.1
   X-Forwarded-Host: whoami.example.com
   ```
   __result:__ The IPv4 address  127.0.0.1 matches the IP address of
   _X-Forwarded-For_
1. Check the IPv4 address of the main network interface.
   Run the command
   ```
   hostname -I
   ```
   The following output is printed
   ```
   192.0.2.5 fd25:c7f8:948a:0:912d:3900:d5c4:45ad
   ```
   __result:__ The IPv4 address of the main network interface is _192.0.2.5_
   (the address furthest to the left)
1. Download the URL __http://whoami.example.com__ from the workerd
   container and see that the request is proxied to the container _whoami.example.com_.
   Resolve _whoami.example.com_ to the IPv4 address of the main network interface.
   Run the command
   ```
   curl -s --resolve whoami.example.com:80:192.0.2.5 \
     http://whoami.example.com | grep X-Forwarded
   ```
   The following output is printed
   ```
   X-Forwarded-For: 192.0.2.5
   X-Forwarded-Host: whoami.example.com
   ```
   __result:__ IPv4 address of _X-Forwarded-For_ matches address of the main network interface

### systemd-analyze security

The command

```
systemd-analyze security workerd.service
```

checks which restrictions have been set on the service _workerd.service_ and estimates the overall exposure level.

By running the command with the environment variable `SYSTEMD_UTF8` set to `0`, ✓ and ✗ are replaced with `+` and `-`.

Show restrictions that would lower the exposure level.

```
SYSTEMD_UTF8=0 systemd-analyze security workerd.service | grep "^- "
```

The following output is printed

```
- RootDirectory=/RootImage=                                   Service runs within the host's root directory                                      0.1
- MemoryDenyWriteExecute=                                     Service may create writable executable memory mappings                             0.1
- RestrictNamespaces=~user                                    Service may create user namespaces                                                 0.3
- RestrictNamespaces=~net                                     Service may create network namespaces                                              0.1
- RestrictNamespaces=~mnt                                     Service may create file system namespaces                                          0.1
- RestrictAddressFamilies=~AF_UNIX                            Service may allocate local sockets                                                 0.1
- RestrictAddressFamilies=~AF_(INET|INET6)                    Service may allocate Internet sockets                                              0.3
- ProtectHome=                                                Service has full access to home directories                                        0.2
- PrivateUsers=                                               Service has access to other users                                                  0.2
- DeviceAllow=                                                Service has a device ACL with some special devices: char-rtc:r                     0.1
```

Show the overall exposure level

```
SYSTEMD_UTF8=0 systemd-analyze security workerd.service | grep "Overall exposure"
```

The following output is printed

```
-> Overall exposure level for workerd.service: 1.3 OK :-)
```

> [!NOTE]
> The exposure level shown by the command `systemd-analyze security workerd.service`
> does not take the whole picture into account because the user account _test_ is
> also running the systemd user service _whoami.service_.

Show the overall exposure level of _whoami.service_. Run as user _test_

```
SYSTEMD_UTF8=0 systemd-analyze --user security whoami.service | grep "Overall exposure"
```

The following output is printed

```
-> Overall exposure level for whoami.service: 10.0 DANGEROUS :-[
```

Do not worry about the high exposure level because `ExecStart=` is configured
to run Podman. When Podman starts the container, Podman will encapsulate and
restrict the container in many ways.

<details>
<summary>Click me</summary>

```
systemctl --user cat whoami.service | grep ExecStart=
```

The following output is printed

```
ExecStart=/usr/bin/podman run --name whoami.example.com --cidfile=%t/%N.cid --replace --rm --cgroups=split --network mynet --sdnotify=conmon -d docker.io/traefik/whoami
```

</details>
