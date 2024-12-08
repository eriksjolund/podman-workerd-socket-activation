return to [main page](../..)

## Example 1

``` mermaid
graph TB

    a1[curl] -.->a2[workerd container]
    a2 -->|"for http&colon;//whoami.example.com"| a3["whoami container"]
```

Set up a systemd user service _example1.service_ for the user _test_ where rootless podman is running the container image _localhost/workerd_.
Configure _socket activation_ for TCP port 80.

1. Verify that unprivileged users are allowed to open port numbers 80 and above.
   Run the command
   ```
   cat /proc/sys/net/ipv4/ip_unprivileged_port_start
   ```
   Make sure the number printed is not higher than 80. To configure the number,
   see https://github.com/eriksjolund/podman-networking-docs#configure-ip_unprivileged_port_start
1. Create a test user
   ```
   sudo useradd test
   ```
1. Open a shell for user _test_
   ```
   sudo machinectl shell --uid=test
   ```
1. Optional step: enable lingering to avoid services from being stopped when the user _test_ logs out.
   ```
   loginctl enable-linger test
   ```
1. Create directories
   ```
   mkdir -p ~/.config/systemd/user
   mkdir -p ~/.config/containers/systemd
   mkdir ~/workerd-example
   ```
1. Pull the _whoami_ container image
   ```
   podman pull docker.io/traefik/whoami
   ```
1. Clone git repo
   ```
   git clone https://github.com/JacobLinCool/workerd-docker.git
   ```
1. Set shell variable to the latest workerd release
   ```
   version=$(curl -Ls https://api.github.com/repos/cloudflare/workerd/releases/latest | jq -r .tag_name)
   ```
   (See also https://github.com/cloudflare/workerd/releases)
1. Build _workerd_ container image
   ```
   podman build --build-arg WORKERD_VERSION=${version} --platform linux/amd64,linux/arm64 -t workerd workerd-docker
   ```
   (The command builds a multiarch container image. To save disk space and reduce build time adjust the __--platform__ option
   to only build for the architecture in use).
1. Clone git repo
   ```
   git clone https://github.com/eriksjolund/podman-workerd-socket-activation.git
   ```
1. Change directory
   ```
   cd podman-workerd-socket-activation/examples/example1/
   ```
1. Install the javascript files
   ```
   cp *.js \
      ~/workerd-example/
   ```
1. Install _config.capnp_
   ```
   cp config.capnp \
      ~/workerd-example/
   ```
1. Install the network unit file
   ```
   cp mynet.network \
      ~/.config/containers/systemd/
   ```
1. Install the container unit files
   ```
   cp *.container \
      ~/.config/containers/systemd/
   ```
1. Install the socket unit files
   ```
   cp workerd.socket ~/.config/systemd/user/
   ```
1. Reload the systemd user manager
   ```
   systemctl --user daemon-reload
   ```
1. Start the _whoami_ container
   ```
   systemctl --user start whoami.service
   ```
1. Start the socket for TCP port 80
   ```
   systemctl --user start workerd.socket
   ```
   If the command fails with
   ```
   Job failed. See "journalctl -xe" for details.
   ```
   then make sure `ip_unprivileged_port_start` is correctly set. See step 1.
1. Download a web page __http://whoami.example.com__ from the workerd
   container and see that the request is proxied to the container _whoami.example.com_.
   Resolve _whoami.example.com_ to _127.0.0.1_.
   ```
   curl -s --resolve whoami.example.com:80:127.0.0.1 \
     http://whoami.example.com | grep X-Forwarded
   ```
   The following output is printed
   ```
   X-Forwarded-For: 127.0.0.1
   X-Forwarded-Host: whoami.example.com
   ```
   __result:__ The IPv4 address  127.0.0.1 matches the IP address of _X-Forwarded-For_ and _X-Real-Ip_
1. Check the IPv4 address of the main network interface.
   Run the command
   ```
   hostname -I
   ```
   The following output is printed
   ```
   192.168.10.108 192.168.39.1 192.168.122.1 fd25:c7f8:948a:0:912d:3900:d5c4:45ad
   ```
   __result:__ The IPv4 address of the main network interface is _192.168.10.108_ (the address furthest to the left)
1. Download a web page __http://whoami.example.com__ from the workerd
   container and see that the request is proxied to the container _whoami.example.com_.
   Resolve _whoami.exampl.com_ to the IP address of the main network interface.
   Run the command
   ```
   curl --resolve whoami.example.com:80:192.168.10.108 \
     http://whoami.example.com | grep X-Forwarded
   ```
   The following output is printed
   ```
   X-Forwarded-For: 192.168.10.108
   X-Forwarded-Host: whoami.example.com
   ```
   __result:__ The IPv4 address of the main network interface, _192.168.10.108_, matches the IPv4 address
   of _X-Forwarded-For_ and _X-Real-Ip_
1. From another computer download a web page __http://whoami.example.com__ from the workerd
   container and see that the request is proxied to the container _whoami.example.com_.
   ```
   curl --resolve whoami.example.com:80:192.168.10.108 \
     http://whoami.example.com | grep X-Forwarded
   ```
   The following output is printed
   ```
   X-Forwarded-For: 192.168.10.161
   X-Forwarded-Host: whoami.example.com
   ```
   Check the IP address of the other computer (which in this example runs macOS).
   In the macOS terminal run the command
   ```
   ipconfig getifaddr en0
   ```
   The following output is printed
   ```
   192.168.10.161
   ```
   __result:__ The IPv4 address of the other computer matches the IPv4 address of _X-Forwarded-For_ and _X-Real-Ip_
   
   __troubleshooting tip:__ If the curl command fails with `Connection timed out` or `Connection refused`,
   then there is probably a firewall blocking the connection. How to open up the firewall is beyond
   the scope of this tutorial.

### Enable debug information

To enable more debug information about the request, uncomment the following line in _fetch.js_

```
// console.log("%o",req);
```

After modifying _fetch.js_, the service needs to be stopped

```
sudo systemctl stop workerd.service
```

Run curl

```
curl -s --resolve whoami.example.com:80:127.0.0.1 \
  http://whoami.example.com
```

To see the journal log, run as user _test_

```
journalctl --user --no-pager -xe
```

Among other things the following output is printed

```
Dec 08 15:41:46 fcos bash[28770]: Request {
Dec 08 15:41:46 fcos bash[28770]:   method: 'GET',
Dec 08 15:41:46 fcos bash[28770]:   url: 'http://whoami.example.com/',
Dec 08 15:41:46 fcos bash[28770]:   headers: Headers(3) {
Dec 08 15:41:46 fcos bash[28770]:     'accept' => '*/*',
Dec 08 15:41:46 fcos bash[28770]:     'host' => 'whoami.example.com',
Dec 08 15:41:46 fcos bash[28770]:     'user-agent' => 'curl/8.10.1',
Dec 08 15:41:46 fcos bash[28770]:     [immutable]: true
Dec 08 15:41:46 fcos bash[28770]:   },
Dec 08 15:41:46 fcos bash[28770]:   redirect: 'manual',
Dec 08 15:41:46 fcos bash[28770]:   fetcher: Fetcher {},
Dec 08 15:41:46 fcos bash[28770]:   signal: AbortSignal { aborted: false, reason: undefined, onabort: null },
Dec 08 15:41:46 fcos bash[28770]:   cf: { clientIp: '[::ffff:127.0.0.1]:50974' },
Dec 08 15:41:46 fcos bash[28770]:   integrity: '',
Dec 08 15:41:46 fcos bash[28770]:   keepalive: false,
Dec 08 15:41:46 fcos bash[28770]:   body: null,
Dec 08 15:41:46 fcos bash[28770]:   bodyUsed: false
Dec 08 15:41:46 fcos bash[28770]: }
```

The same output can be seen with this sudo command

```
sudo systemd-run --user --machine test@ --quiet --user --collect --pipe --wait journalctl --user --no-pager -xe
```

### Using `Internal=true`

The file [_mynet.network_](mynet.network) currently contains

```
[Network]
Internal=true
```

The line

```
Internal=true
```

prevents containers on the network to connect to the internet.
To allow Containers on the network to download files from the internet you would need to remove the line.
