# iris
InterSystems IRIS
InterSystems Caché Database

            
docker pull intersystems/irishealth-community:latest-preview

docker run --rm -p 52773:52773 --init --name my-iris intersystems/irishealth-community:latest-preview

Then open Management portal in your host browser on:
http://localhost:52773/csp/sys/UtilHome.csp

Or open a terminal to IRIS:
docker exec -it my-iris iris session IRIS

Stop IRIS container when you don't need it:
docker stop my-iris

docker run --name iris -d --publish 1972:1972 --publish 52773:52773 containers.intersystems.com/intersystems/iris-community:2022.1.0.209.0 --check-caps false