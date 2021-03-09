# Prometheus IPMI Exporter

This is an IPMI exporter for [Prometheus](https://prometheus.io).

It supports both the regular `/metrics` endpoint, exposing metrics from the
host that the exporter is running on, as well as an `/ipmi` endpoint that
supports IPMI over RMCP - one exporter running on one host can be used to
monitor a large number of IPMI interfaces by passing the `target` parameter to
a scrape.

The exporter relies on tools from the
[FreeIPMI](https://www.gnu.org/software/freeipmi/) suite for the actual IPMI
implementation.

<<<<<<< HEAD
## Running in Docker
=======
## Installation

For most use-cases, simply download the [the latest
release](https://github.com/soundcloud/ipmi_exporter/releases).

### Building from source

You need a Go development environment. Then, simply run `make` to build the
executable:

    make

This uses the common prometheus tooling to build and run some tests.

Alternatively, you can use the standard Go tooling, which will install the
executable in `$GOPATH/bin`:

    go get github.com/soundcloud/ipmi_exporter

### Building a Docker container

You can build a Docker container with the included `docker` make target:

    make docker

This will not even require Go tooling on the host. See the included [docker
compose example](docker-compose.yml) for how to use the resulting container.

## Running

A minimal invocation looks like this:

    ./ipmi_exporter

Supported parameters include:

 - `web.listen-address`: the address/port to listen on (default: `":9290"`)
 - `config.file`: path to the configuration file (default: none)
 - `freeipmi.path`: path to the FreeIPMI executables (default: rely on `$PATH`)

For syntax and a complete list of available parameters, run:

    ./ipmi_exporter -h

Make sure you have the following tools from the
[FreeIPMI](https://www.gnu.org/software/freeipmi/) suite installed:

 - `ipmimonitoring`/`ipmi-sensors`
 - `ipmi-dcmi`
 - `ipmi-raw`
 - `bmc-info`
 - `ipmi-sel`
 - `ipmi-chassis`

### Running as unprivileged user

If you are running the exporter as unprivileged user, but need to execute the
FreeIPMI tools as root, you can do the following:

  1. Add sudoers files to permit the following commands
     ```
     ipmi-exporter ALL = NOPASSWD: /usr/sbin/ipmimonitoring,\
                                   /usr/sbin/ipmi-sensors,\
                                   /usr/sbin/ipmi-dcmi,\
                                   /usr/sbin/ipmi-raw,\
                                   /usr/sbin/bmc-info,\
                                   /usr/sbin/ipmi-chassis,\
                                   /usr/sbin/ipmi-sel
     ```
  2. Create the script under user dir with execute permission
     ```bash
     #!/bin/sh
     sudo /usr/sbin/$(basename $0) "$@"
     ```
  3. Create symlinks under user dir
      ```bash
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/ipmimonitoring
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/ipmi-sensors
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/ipmi-dcmi
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/ipmi-raw
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/bmc-info
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/ipmi-chassis
      ln -s /home/ipmi-exporter/[script name] /home/ipmi-exporter/ipmi-raw
      ````
  4. Execute ipmi-exporter with the option `--freeipmi.path=/home/ipmi-exporter`
>>>>>>> upstream/master

``` shell
docker run -d --name ipmi-exporter \
  -p 9290:9290 \
  -e IPMIUSER="root" \
  -e IPMIPASSWORD="YourPassword" \
  darren00/ipmi-exporter
```

### Using Docker Compose

`docker-compose.yml`:

``` yaml
version: '3.5'
services:
  ipmi-exporter:
    image: darren00/ipmi-exporter
    restart: always
    environment:
      IPMIUSER: "root"                      # default ipmi user
      IPMIPASSWORD: "YourPassword"          # default ipmi password
    volumes:
      - ./ipmi_remote.yml:/config.yml:ro    # replace with your own config
    ports:
      - 9290:9290
```

## Prometheus configuration example

``` yaml
scrape_configs:
  - job_name: ipmi
    params:
      module: ["default"]
    scrape_interval: 1m
    metrics_path: /ipmi
    scheme: http
    static_config:
      targets:
        # Remote IPMI hosts.
        - 10.2.0.10
        - 10.2.0.11
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: ipmi-exporter:9290
```
<<<<<<< HEAD
=======

For more information, e.g. how to use mechanisms other than a file to discover
the list of hosts to scrape, please refer to the [Prometheus
documentation](https://prometheus.io/docs).

## Exported data

### Scrape meta data

These metrics provide data about the scrape itself:

 - `ipmi_up{collector="<NAME>"}` is `1` if the data for this collector could
   successfully be retrieved from the remote host, `0` otherwise. The following
   collectors are available and can be enabled or disabled in the config:
   - `ipmi`: collects IPMI sensor data. If it fails, sensor metrics (see below)
     will not be available
   - `dcmi`: collects DCMI data, currently only power consumption. If it fails,
     power consumption metrics (see below) will not be available
   - `bmc`: collects BMC details. If it fails, BMC info metrics (see below)
     will not be available
   - `chassis`: collects the current chassis power state (on/off). If it fails,
     the chassis power state metric (see below) will not be available
   - `sel`: collects system event log (SEL) details. If it fails, SEL metrics
     (see below) will not be available
   - `sm-lan-mode`: collects the "LAN mode" setting in the current BMC config.
     If it fails, the LAN mode metric (see below) will not be available
 - `ipmi_scrape_duration_seconds` is the amount of time it took to retrieve the
   data

### BMC info

This metric is only provided if the `bmc` collector is enabled.

For some basic information, there is a constant metric `ipmi_bmc_info` with
value `1` and labels providing the firmware revision and manufacturer as
returned from the BMC, and the host system's firmware version (usually the BIOS
version). Example:

    ipmi_bmc_info{firmware_revision="1.66",manufacturer_id="Dell Inc. (674)",system_firmware_version="2.6.1"} 1

**Note:** some systems do not expose the system's firmware version, in which
case it will be exported as `"N/A"`.

### Chassis Power State

This metric is only provided if the `chassis` collector is enabled.

The metric `ipmi_chassis_power_state` shows the current chassis power state of
the machine.  The value is 1 for power on, and 0 otherwise.

### Power consumption

This metric is only provided if the `dcmi` collector is enabled.

The metric `ipmi_dcmi_power_consumption_current_watts` can be used to monitor
the live power consumption of the machine in Watts. If in doubt, this metric
should be used over any of the sensor data (see below), even if their name
might suggest that they measure the same thing. This metric has no labels.

### System event log (SEL) info

These metrics are only provided if the `sel` collector is enabled (it isn't by
default).

The metric `ipmi_sel_entries_count` contains the current number of entries in
the SEL. It is a gauge, as the SEL can be cleared at any time. This metric has
no labels.

The metric `ipmi_sel_free_space_bytes` contains the current number of free
space for new SEL entries, in bytes. This metric has no labels.

### Supermicro LAN mode setting

This metric is only provided if the `sm-lan-mode` collector is enabled (it
isn't by default).

**NOTE:** This is a vendor-specific collector, it will only work on Supermicro
hardware, possibly even only on _some_ Supermicro systems.

**NOTE:** Retrieving this setting requires setting `privilege: "admin"` in the
config.

See e.g. https://www.supermicro.com/support/faqs/faq.cfm?faq=28159

The metric `ipmi_config_lan_mode` contains the value for the current "LAN mode"
setting (see link above): `0` for "dedicated", `1` for "shared", and `2` for
"failover".

### Sensors

These metrics are only provided if the `ipmi` collector is enabled.

IPMI sensors in general have one or two distinct pieces of information that are
of interest: a value and/or a state. The exporter always exports both, even if
the value is NaN or the state non-sensical. This is so one can still always
find the metrics to avoid ending up in a situation where one is looking for
e.g. the value of a sensor that is in a critical state, but can't find it and
assume this to be a problem.

The state of a sensor can be one of _nominal_, _warning_, _critical_, or _N/A_,
reflected by the metric values `0`, `1`, `2`, and `NaN` respectively. Think of
this as a kind of severity.

For sensors with known semantics (i.e. units), corresponding specific metrics
are exported. For everything else, generic metrics are exported.

#### Temperature sensors

Temperature sensors measure a temperature in degrees Celsius and their state
usually reflects the temperature going above the vendor-recommended value. For
each temperature sensor, two metrics are exported (state and value), using the
sensor ID and the sensor name as labels. Example:

    ipmi_temperature_celsius{id="18",name="Inlet Temp"} 24
    ipmi_temperature_state{id="18",name="Inlet Temp"} 0

#### Fan speed sensors

Fan speed sensors measure fan speed in rotations per minute (RPM) and their
state usually reflects the speed being to low, indicating the fan might be
broken. For each fan speed sensor, two metrics are exported (state and value),
using the sensor ID and the sensor name as labels. Example:

    ipmi_fan_speed_rpm{id="12",name="Fan1A"} 4560
    ipmi_fan_speed_state{id="12",name="Fan1A"} 0

#### Voltage sensors

Voltage sensors measure a voltage in Volts. For each voltage sensor, two
metrics are exported (state and value), using the sensor ID and the sensor name
as labels. Example:

    ipmi_voltage_state{id="2416",name="12V"} 0
    ipmi_voltage_volts{id="2416",name="12V"} 12

#### Current sensors

Current sensors measure a current in Amperes. For each current sensor, two
metrics are exported (state and value), using the sensor ID and the sensor name
as labels. Example:

    ipmi_current_state{id="83",name="Current 1"} 0
    ipmi_current_amperes{id="83",name="Current 1"} 0

#### Power sensors

Power sensors measure power in Watts. For each power sensor, two metrics are
exported (state and value), using the sensor ID and the sensor name as labels.
Example:

    ipmi_power_state{id="90",name="Pwr Consumption"} 0
    ipmi_power_watts{id="90",name="Pwr Consumption"} 70

Note that based on our observations, this may or may not be a reading
reflecting the actual live power consumption. We recommend using the more
explicit [power consumption metrics](#power_consumption) for this.

#### Generic sensors

For all sensors that can not be classified, two generic metrics are exported,
the state and the value.  However, to provide a little more context, the sensor
type is added as label (in addition to name and ID). Example:

    ipmi_sensor_state{id="139",name="Power Cable",type="Cable/Interconnect"} 0
    ipmi_sensor_value{id="139",name="Power Cable",type="Cable/Interconnect"} NaN
>>>>>>> upstream/master
