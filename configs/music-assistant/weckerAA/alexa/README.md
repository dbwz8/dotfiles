# Alexa speakers on weckerAA

This is the bridge needed to use Alexa/Echo devices as Music Assistant players.
It is required even when playback is controlled only from Music Assistant: the
custom skill is the transport path Echo devices use to retrieve MA audio.

The active `weckerAA` deployment is `/opt/music-assistant-alexa`. Manage it
with `bash scripts/music-assistant-alexa <up|update|status|logs>`. Do not run a
second Compose project from this directory on `weckerAA`; it would conflict on
the bridge's private port, `127.0.0.1:5000`.

## Template deployment

On a new host, create the local configuration and credentials:

```sh
cd configs/music-assistant/weckerAA/alexa
cp .env.example .env
mkdir -p ask_data secrets
chmod 700 ask_data secrets
printf '%s' 'choose-a-long-random-username' > secrets/app_username.txt
printf '%s' 'choose-a-long-random-password' > secrets/app_password.txt
chmod 600 secrets/app_username.txt secrets/app_password.txt
docker compose up -d
```

The service deliberately binds only to `127.0.0.1:5000`. The Music Assistant
server runs with host networking and can use this local API, while Cloudflare
Tunnel is the only public path to the skill endpoint.

## Cloudflare Tunnel

Configure these three public hostnames on the dedicated
`music-assistant-alexa` tunnel. The service field is the origin service on
`weckerAA`:

| Hostname | Service |
| --- | --- |
| `music.dbwz8.com` | `http://127.0.0.1:8095` |
| `alexa.dbwz8.com` | `http://127.0.0.1:5000` |
| `stream.dbwz8.com` | `http://127.0.0.1:8097` |

The existing `ssh-tunnel` is remotely managed and ignores its local ingress
file, so these routes cannot be added to it. For a locally managed tunnel,
merge `cloudflared-ingress.yaml.example` into its active configuration. Each
hostname needs a proxied CNAME to that tunnel's `cfargotunnel.com` target.

Do not put Cloudflare Access, a login page, bot challenges, or a restrictive
WAF rule in front of either hostname. Keep Cloudflare's minimum TLS version at
1.2, rather than TLS-1.3-only.

## Initial skill setup

Open `http://127.0.0.1:5000/setup` from `weckerAA` (or use SSH port forwarding)
to authenticate the ASK CLI and create/update the development skill. Set its
HTTPS endpoint to `https://alexa.dbwz8.com`; enable Audio Player and APL.
Use `http://127.0.0.1:5000/status` to confirm the skill endpoint and testing
status are green.

Keep the Alexa-app skill name as `Music Assistant`, but use the unique
invocation name `wecker music`. Music Assistant sends that invocation itself
when it starts an Alexa stream, so normal playback remains entirely in MA.
Set `MA_ALEXA_SKILL_ID` in the server `.env` to the Alexa Developer Console
skill ID. MA launches that exact private skill directly, avoiding Alexa's
speech interpretation and default music-service fallbacks.
MA uses Alexa's device media controls for pause, resume, and stop; those
actions do not depend on a spoken skill command.

## Music Assistant Alexa provider

In the MA Alexa player provider use:

- API URL: `http://127.0.0.1:5000`
- API Basic Auth Username: the content of `secrets/app_username.txt`
- API Basic Auth Password: the content of `secrets/app_password.txt`
- Alexa Language: the same locale as `ALEXA_LOCALE`

Add the Amazon account, password, and OTP secret in the provider UI. Alexa
devices will then appear as MA players. The Amazon Alexa app is needed only to
enable the development skill; playback is selected and controlled from MA.

Music Assistant cannot provide true synchronized Alexa multi-room playback.
For Alexa Household devices, MA routes custom commands through each speaker's
owner account so a speaker such as Kitchen does not fall back to its default
music service (for example, Pandora).

## Current Music Assistant compatibility fix

The `weckerAA/compose.yaml` mounts `overrides/sitecustomize.py`. It applies the
small, idempotent workaround required by Music Assistant 2.9.12 for Amazon's
CVF callback paths, its WAF interceptor, and the unique Alexa invocation.
It runs only inside the MA container. On a future MA update, inspect its logs:
if upstream changed the provider implementation, the workaround skips itself
instead of modifying unfamiliar code.
