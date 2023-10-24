# Anvil system striker web interface API

## About NPM projects
In essence, this module and the striker web interface module share the same management workflows:
* All `npm` commands must be executed at the project root or lower level(s).
* To prepare the workspace, run `npm install`.
* To produce a production build, run `npm run build`.

One major difference is there's no live development mode in this project.

See the striker we interface's [README](../striker-ui/README.md) for more details.

## Run prerequisites
* This API module is targetted at NodeJS version 10, which is the default on CentOS/RHEL 8.
* All executables/files listed in `src/lib/consts/SERVER_PATHS.ts` and their respective dependencies are required.

## Build
Run `npm run build` to produce a minified script at `out/index.js`. The output script can be executed with NodeJS assuming all prerequisites are met.

There's no need to remove the old build prior to a new build because the build process always overwrites the one file.

`systemd` expects the build to be placed exactly at `/usr/share/striker-ui-api/index.js` on a striker.

## Logs
At the time of writing, no logging library was added. Logs are either `stdout` or `stderr` without levels. When the API runs as a service, its logs can be viewed with `journalctl --unit striker-ui-api`.

Due to the large amount of logs produced, it's highly recommended to note the time of a test, and specify a time frame with `journalctl --since <date parsable time> --until <date parsable time>` to help with the search.

## Systemd service
The service file of this API module is located in `../units/`. Environment varibles can be set with the `Environment=<variable name>=<value>` directive, i.e., to set the main server's port to `80`, use `Environment=PORT=80`.

## Environment varibles
Variables can be set to affect the API's funtionalities, i.e. listen on a different port. A complete list with explanations is located at `src/lib/consts/ENV.ts`
