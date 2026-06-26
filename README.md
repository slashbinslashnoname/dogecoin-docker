# dogecoin-docker

![Doge riding a rocket to the moon](assets/doge-to-the-moon.webp)

Unofficial, automatically-built Docker images of [Dogecoin Core](https://github.com/dogecoin/dogecoin).

A scheduled GitHub Actions workflow polls `dogecoin/dogecoin` for new release tags
(`v1.x.y`) and builds a multi-arch image for any tag it hasn't published yet, so
every Dogecoin release ends up as a container image without manual work.

> **Why polling and not a tag trigger?** GitHub only delivers tag/push events to
> workflows *inside* the repository where the tag is created. Since we don't own
> `dogecoin/dogecoin`, we poll its tags on a schedule instead (daily).

## Images

Published to GitHub Container Registry:

```
ghcr.io/slashbinslashnoname/dogecoind
```

Tags:

| Tag        | Points to                                  |
|------------|--------------------------------------------|
| `1.14.9`   | that exact release                         |
| `1.14`     | latest patch of the `1.14` line            |
| `latest`   | the newest released version overall        |

Architectures: `linux/amd64`, `linux/arm64`.

## Usage

### Run a node

```bash
docker run -d --name dogecoind \
  -v dogecoin-data:/home/dogecoin/.dogecoin \
  -p 22556:22556 \
  ghcr.io/slashbinslashnoname/dogecoind:latest
```

- Port `22556` is the P2P port (mainnet). Map `22555` too if you need RPC exposed.
- The named volume `dogecoin-data` persists the blockchain across restarts.

### Pass dogecoind options

Anything after the image name is passed to `dogecoind`:

```bash
docker run -d --name dogecoind \
  -v dogecoin-data:/home/dogecoin/.dogecoin \
  ghcr.io/slashbinslashnoname/dogecoind:latest \
  -printtoconsole -rpcuser=doge -rpcpassword=changeme -rpcallowip=172.0.0.0/8
```

### Use the CLI

The image also ships `dogecoin-cli`:

```bash
docker exec dogecoind dogecoin-cli getblockchaininfo
```

### docker-compose

```yaml
services:
  dogecoind:
    image: ghcr.io/slashbinslashnoname/dogecoind:latest
    restart: unless-stopped
    volumes:
      - dogecoin-data:/home/dogecoin/.dogecoin
    ports:
      - "22556:22556"
    command: ["-printtoconsole"]

volumes:
  dogecoin-data:
```

## How it works

- **`.github/workflows/build.yml`** — runs on a daily cron (and on manual
  `workflow_dispatch`). The `discover` job lists upstream tags, subtracts the tags
  already in the registry, and feeds the remainder into a build matrix. Re-runs are
  cheap no-ops; the first run backfills the whole release history.
- **`Dockerfile`** — a multi-stage build. CI checks out the dogecoin source *at the
  target tag* into the build context, so `COPY . .` compiles that exact release.

### Run it manually

From the repo's **Actions** tab → **Build Dogecoin images** → **Run workflow**.
Or with the GitHub CLI:

```bash
gh workflow run build.yml
```

### Adjust the schedule

Edit the `cron:` line in `.github/workflows/build.yml`. Note GitHub may delay
scheduled runs on free runners during peak load.

## Verifying an image

Builds publish provenance and an SBOM. Inspect with:

```bash
docker buildx imagetools inspect ghcr.io/slashbinslashnoname/dogecoind:latest
```

## Disclaimer

These are **community builds**, not official Dogecoin releases. They are compiled
from upstream source in public CI; review the `Dockerfile` and workflow before
running in production. For maximum trust, verify against the official
[Gitian release binaries](https://github.com/dogecoin/dogecoin/releases).
