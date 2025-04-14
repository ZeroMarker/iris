# Build

maven 3.6.3

maven mirror, snapshot

shorten command line , classpath

## data source

```yml
bootstrap.yml
                    - data-id: config-common-serveraddress-local.yml
                      refresh: true
                    - data-id: config-common-applications.yml
                      refresh: true

mediway:
    application:
        mrm: mrm-mediway-server
        deploy-mode: "single"
        phkm: phkm-mediway-server
        mrfs: mrfs-mediway-server
        peis: peis-mediway-server

```
