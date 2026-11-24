# course-labs

Hands-on labs for the free courses on **[abhishekkothari.in](https://abhishekkothari.in)**.

Each course with a hands-on section has its own folder here. A folder appears only when its course
is published, and lessons link straight to the lab they use. No labs are published yet. The first
folder will appear with the first course release.

```
course-labs/
├── <course-slug>/
│   ├── README.md          what the labs cover and what you need
│   ├── 01-<lab-name>/     one folder per lab: compose file, configs, small scripts
│   └── 02-<lab-name>/
└── ...
```

## What you need

- **Docker** with Compose v2: Docker Desktop on macOS or Windows, Docker Engine plus the Compose
  plugin on Linux. Check with `docker compose version`.
- **git**, to clone this repo.
- No cloud account, credit card or API key. Everything runs on your own machine, but you need an
  internet connection the first time, to download container images and models. Cloud labs use a local
  AWS emulator, Kubernetes labs use [kind](https://kind.sigs.k8s.io/), and LLM labs use a local model.
  Each course README lists how much RAM and disk its labs need, and any extra tools (for example `kind`
  and `kubectl`).

## Using a lab

```bash
git clone https://github.com/datsabk/course-labs.git
cd course-labs/<course-slug>/<lab-folder>
docker compose up -d        # start the lab
docker compose down -v      # stop it and delete its volumes (the lab's data)
```

Each lab folder's README lists the ports it opens and what you should see. Kubernetes labs may use a
setup script instead of a compose file, so follow the lab's README. Labs bind to `localhost`
only and are meant for learning on your own machine, not for production.

## How these labs are made

The courses and their labs are written by Claude (an AI model). They then go through an automated
review loop with a second AI model (Kimi K3): three rounds of review and revision, plus a final check
of the last changes. Nothing is published until that loop is finished. The labs are reviewed but
not run automatically before release, so mistakes can slip through. If a lab doesn't work as described, please
[open an issue](https://github.com/datsabk/course-labs/issues) with the course, the lab folder, your
OS, the output of `docker compose version` and the error output.

## License

Everything in this repository is released under the [MIT License](LICENSE). The course lessons on
abhishekkothari.in are separate and are not covered by it. Third-party container images and models
used by the labs keep their own licenses.
