# Nerves.SSDPServer

**Simple Server for the <u>S</u>imple <u>S</u>ervices <u>D</u>iscovery <u>P</u>rotocol**

[SSDP](https://en.wikipedia.org/wiki/Simple_Service_Discovery_Protocol) allows devices on LAN to announce themselves and their services to other devices. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add nerves_ssdp_server to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_ssdp_server, "~> 0.0.1"}]
        end

  2. Ensure nerves_ssdp_server is started before your application:

        def application do
          [applications: [:nerves_ssdp_server]]
        end

## Usage

In SSDP, every service needs to define a USN (unique service name), and a ST (service type).  That's the minimum required to publish a service.  With that info, it's as simple as this:

```elixir
alias Nerves.SSDPServer

SSDPServer.publish "my_unique_service_name", "my-service-type"
```
### Publishing custom fields

Other parameters you might specify for the second parameter to `publish` are included as fields of the published service.  For instance, you can do..

```elixir
alias Nerves.SSDPServer

@ssdp_fields [
    location: "http://localhost:3000/myservice.json",
    server: "MyServerName",
    "cache-control": "max-age=1800"
]

SSDPServer.publish "my-service-name", "my-service-type", @ssdp_fields
```

You can call `publish` to publish multiple services, each with a unique USN, but you can only publish each USN once, as per the SSDP spec.

## The nerves-project-org:service:cell:1 service type

- LOCATION if present, specifies a URL to grab a cell description

## References

Here is are some links with background information about SSDP.

http://www.w3.org/TR/discovery-api/#simple-service-discovery-protocol-ssdp
http://www.upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.0-20080424.pdf

