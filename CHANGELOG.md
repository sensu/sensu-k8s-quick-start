# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/). 
This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

### Contributors 

- @jjasghar
- @calebhailey

### Added

- Use the Downward API to set `KUBE_NAMESPACE` variables to make the template more portable (avoid hard-coded namespaces in DNS/hostnames). 
- New Kubernetes Batch job for innitializing the Sensu cluster (i.e. running `sensu-backend init`). 
- Added new `sensu-etcd` StatefulSet (i.e. standalone Etcd). 
- Exposing more `sensu-backend` and `sensu-agent` configuration as environment variables (including some default settings for ease of customization). 

### Changed

- Updated Sensu from version 5.16.3 to 6.2.5 (!). 
- Merged the Sensu backend Kubernetes templates into a single file (`kubernetes/sensu-backend.yaml`); 
  this replaces `kubernetes/sensu-backend-service.yaml` and `kubernetes/sensu-backend-statefulset.yaml`. 
- Renamed the `sensu` service to `sensu-etcd`. 
- Disabled Sensu's embedded Etcd in favor of standalone Etcd. 
- Refactored the README (one line per sentence for simplified collaboration). 
- Updated TODO section of the README.

## [2020-01-15] version 0.0.0 (untagged release)

### Contributors 

- @calebhailey
- @jspaleta 
- @nixwiz

### Added 

- Initialized this project! 
- Example Kubernetes StatefulSet for Sensu Go. 
- Example Kubernetes sidecar for Sensu Go. 
- Bootstrapped a README with instructions on getting started and some basic troubleshooting tips.

