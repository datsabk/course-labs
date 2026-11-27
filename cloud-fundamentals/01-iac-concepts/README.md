# 01-iac-concepts: why an imperative script is hard to re-run

Used by lesson 15 of Cloud Fundamentals, **Infrastructure as Code Explained for Beginners**.

You start LocalStack, run a small script that creates a storage bucket, run it again, and count the buckets. You
end up with two, because an imperative script performs its step every time it runs. The next lessons replace the
script with Terraform, which compares what you asked for with what exists and changes only the difference.

## What is in this folder

| File | What it does |
| --- | --- |
| `docker-compose.yml` | Starts LocalStack, an emulator of AWS APIs, pinned to `localstack/localstack:4.14.0` |
| `create-bucket.sh` | Makes up a new bucket name (`iac-demo-` plus the UTC date and time and a random number) and creates that bucket |
| `list-buckets.sh` | Lists every bucket in LocalStack: creation date and time, then name |

Both scripts run the AWS CLI that ships inside the LocalStack container, with the dummy credentials `test` / `test`
and the region `us-east-1`, so for this lab you need only Docker with Compose v2 and a bash shell (on Windows, WSL 2).
You do not need an AWS account, the AWS CLI on your machine, or Terraform yet.

## Port

LocalStack listens on port **4566**, published on 127.0.0.1 only, so only your own machine can reach it. If another
lab or program already uses port 4566, stop it first (in another lab folder, run `docker compose down -v`).

## Why LocalStack 4.14.0

Since March 2026, newer LocalStack images (`latest` and the `2026.x` versions) need a LocalStack account and an auth
token to start. Version 4.14.0 is the last release that starts without one, so this lab pins it. It no longer gets
updates, which is one more reason its port listens on 127.0.0.1 only. Keep the tag as it is.

## Start it

```sh
cd course-labs/cloud-fundamentals/01-iac-concepts
docker compose up -d
```

The first run downloads the image, which can take a few minutes. Later starts are quick.

## Check that it works

```sh
docker compose ps
```

You should see the `localstack` service with a status that starts with `Up` and ends with `(healthy)`, for example
`Up 30 seconds (healthy)`. For the first few seconds it says `(health: starting)`; wait and run the command again.

Optionally, ask LocalStack itself:

```sh
curl http://localhost:4566/_localstack/health
```

You should see a JSON document that lists the emulated services and their state, with `"s3"` among them, marked
`"available"` (or `"running"` once you have used it).

## Run the experiment

```sh
bash create-bucket.sh
bash create-bucket.sh
bash list-buckets.sh
```

You should see:

- After each `create-bucket.sh`, one line such as `make_bucket: iac-demo-20261127-101530-4821`. Your date, time and
  number will differ, and the second run prints a different name from the first.
- After `list-buckets.sh`, two lines, one per bucket, each a creation date and time followed by a name, for example
  (illustrative):

  ```text
  2026-11-27 10:15:30 iac-demo-20261127-101530-4821
  2026-11-27 10:15:41 iac-demo-20261127-101541-17206
  ```

The same script, run twice, gave two different buckets. Every extra run adds one more.

## Stop it and clean up

```sh
docker compose down -v
```

This stops and removes the LocalStack container. The lab does not turn on LocalStack's persistence, so the buckets
are gone too, and the next `docker compose up -d` starts empty. Run it in this folder: Compose finds the lab through
its `docker-compose.yml`.

## Troubleshooting

- **`docker compose up` fails with "port is already allocated":** something else uses port 4566. Run
  `docker compose down -v` in the other lab folder, or stop the other program, then try again.
- **"Cannot connect to the Docker daemon":** Docker is not running. Start Docker Desktop (or the Docker service on
  Linux) and wait until `docker info` works.
- **`service "localstack" is not running`:** LocalStack is not started in this folder. Run `docker compose up -d` here.
- **`make_bucket failed: ... Could not connect to the endpoint URL`:** the container is up but LocalStack inside it is
  still starting. Wait until `docker compose ps` shows `(healthy)`, then run the script again.
- **`list-buckets.sh` prints nothing:** there are no buckets. LocalStack starts empty after every restart, so run
  `create-bucket.sh` again.
- **LocalStack exits right after it starts, and `docker compose logs localstack` mentions credentials or an auth
  token:** the image tag in `docker-compose.yml` was changed to a newer version. Put back `localstack/localstack:4.14.0`.
