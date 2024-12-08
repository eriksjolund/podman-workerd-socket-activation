return to [main page](../..)

## Example 2

``` mermaid
graph TB

    a1[curl] -.->a2[workerd container]
    a2 -->|"for http&colon;//whoami.example.com"| a3["whoami container"]
```

This example is similar to [Example1](../example1) but here `workerd` forwards
the request to the IP address that the URL domain name resolves to.
Although `workerd` is configured to allow forwarding to any IP address (`0.0.0.0/0`),
no requests will be forwarded to internet because the workerd container is running
on an internal custom network (see [../example1/mynet.network](../example1/mynet.network)).

Make sure the file _mynet.network_ has the configuration line
```
Internal=true
```

Use the instructions from  [Example1](../example1) but replace the files from this directory.
In other words, Example 2 uses these files

* [../example1/mynet.network](../example1/mynet.network)
* [../example1/whoami.container](../example1/whoami.container)
* [../example1/workerd.container](../example1/workerd.container)
* [../example1/workerd.socket](../example1/workerd.socket)
* [../example1/library.js](../example1/library.js)
* [./config.capnp](config.capnp)
* [./fetch.js](fetch.js)
