# Anvil system striker web interface

# Notes

- All NPM commands **must** be executed at the root folder of this UI module, where the `package.json` is located.
- For those unfamiliar with git and/or the web technologies involved, it's highly recommended to clone a fresh repo as a test workspace.

## Development prerequisites

- NodeJS LTS is recommended, version >= 14 is required.
- NPM latest is recommended, version >= 6 is required.

"required" means this project was started with roughly the specified version; earlier version may work.

For Fedora, NPM is included as a dependency of NodeJS; running `sudo dnf install nodejs` should be enough.

## Installation

Run `npm install` to download all production and development dependencies. The NPM packages will be collectively placed into a folder named `node_modules` in the root of this project.

## Live development

Run `npm run dev` to start a local development server that listens on port 3000. Any source code changes after the dev server has started will trigger a quick partial rebuild, the changes will be reflected shortly in the browser.

However, it's highly recommended to perform a clear-cache reload, which is usually `CTRL` + `F5`, because changes may not always reflect correctly.

## Production build

Run `rm -rf out && npm run build` to remove the existing build output and generate a new one. It's highly recommended to remove the old build before building a new one because the some of the generated files won't replace the old files, thus old files will remain when the whole output directory gets committed/copied.

The build is expected to be placed into the `/var/www/html/` directory on a striker.

At the time of writing, the build is committed to the repository to keep the whole project's building process offline. NPM requires network to fetch dependencies before building. Ideally, the build shouldn't be included, but we cannot remove the it from repo until there's a reliable way to separate the download and build tasks.

## Logs

At the time of writing, no logging library has been added due to other priorities. The recommended debug logging is to temporarily add any appropriate `console` functions to suspicious areas, i.e. before and after the location where an exception was thrown.

## Test with striker API

Most of the API requires authentication to access. At the time of writing, the striker API can only produce cookies with its domain (including port) after successfully authenticating a user. Therefore, the striker UI must be accessed from the same location to allow the browser to read the session cookies.

There are 2 tested methods to achive same-domain:

1. Make changes to the source and produce a **production** build. Copy the new build to the striker and access the UI by connecting to the striker.
2. Install a proxy/load balance server, forward `<domain>/` (root) to the server hosting the web UI, and forward `<domain>/api/` to the API. When accessing the UI, the browser only accesses the proxy and will consider the two locations to be under the same domain. thus it will see the cookies produced by authentication. A recommended server with easy-to-understand configuration is `nginx`; it's available via `dnf`.
