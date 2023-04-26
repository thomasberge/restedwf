![GitHub Logo](images/logo_small.png)

# Alpha release 0.7.0

An attempt at creating a scoped-down MVP version that is realistic to get to a finalized state. Features will be removed and later (perhaps) re-implemented.

Functionality split into `server` and `core`. A `core` is a self-contained HTTP server that can run with one or more worker threads. No data is shared between them. The `server` is the instance that connects workers or even multiple cores together. All server-core communication is over HTTP, allowing for a `server` to contain multiple `cores` spread over several cloud/physical servers. 
