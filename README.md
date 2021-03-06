# Nominatim container image for Openshift

For details on Nominatim and OpenShift see https://github.com/openstreetmap/Nominatim, https://www.openshift.com/.

Containers for OpenShift should run as non-root users, see https://docs.openshift.com/container-platform/3.9/creating_images/guidelines.html. Therefore, existing Docker images for nominatim, e.g. https://github.com/mediagis/nominatim-docker, https://github.com/merlinnot/nominatim-docker, do not work.

Nominatim currently does not support running postgres on remote hosts, see https://github.com/openstreetmap/Nominatim/issues/318.

## Build with Docker

```
docker build -t nominatim .
```

## Run with Docker
```
docker run -p 8080:8080 nominatim
```

# Test with Docker

http://localhost:8080/nominatim/search?q=7+Rue+de+Millo,+98000+Monaco&format=json

should return something like

```
[{"place_id":"101334","licence":"Data © OpenStreetMap contributors, ODbL 1.0. https:\/\/www.openstreetmap.org\/copyright","osm_type":"way","osm_id":"176674531","boundingbox":["43.7330672","43.733166","7.4200543","7.4212586"],"lat":"43.733166","lon":"7.4212586","display_name":"Rue de Millo, La Condamine, Monaco, 98000, Monaco","class":"highway","type":"residential","importance":0.545}]
```

# Build with OpenShift
```
oc new-build --strategy docker --binary --docker-image centos:7 --name nominatim
# Alternative: oc new-build --strategy docker --binary --docker-image centos/s2i-core-centos7 --name nominatim
oc start-build nominatim --from-dir . --follow
```

## Mount volumes

```
oc set volume dc/nominatim --add --name=pbf-data --claim-name=pbf-data --mount-path=/var/lib/nominatim/pbf
oc set volume dc/nominatim --add --name=osm-pgs --claim-name=osm-pgs --mount-path=/var/lib/pgsql/data
oc set volume dc/nominatim --add --name=osm-flat-file --claim-name=osm-flat-file --mount-path=/var/lib/nominatim/data
```

## Clear Volumes

see https://blog.openshift.com/transferring-files-in-and-out-of-containers-in-openshift-part-3/

```
oc run dummy --image centos/httpd-24-centos7
# Wait for rollout to finish
oc rollout status dc/dummy
# Mount persistent volume
oc set volume dc/dummy --add --name=tmp-mount --claim-name=osm-psg --mount-path=/mnt
# Wait for rollout to finish
oc rollout status dc/dummy
# Get pod
oc get pods
# ssh on pod
oc rsh dummy-2-vzxh5
```