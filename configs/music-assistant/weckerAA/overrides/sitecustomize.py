"""Apply the temporary Alexa-provider compatibility fix at container startup.

Music Assistant 2.9.12's Alexa login flow does not proxy all of Amazon's
Customer Verification Flow callbacks.  It also uses the generic public skill
invocation, which can resolve to an unrelated enabled skill.  Patch the
installed provider before Music Assistant imports it.  Each replacement is
idempotent so a container restart is safe; a changed upstream implementation
is left untouched and reported rather than guessed at.
"""

from __future__ import annotations

from pathlib import Path


PROVIDER = Path(__file__).parent / "music_assistant/providers/alexa/__init__.py"

REPLACEMENTS = (
    (
        "from alexapy import AlexaAPI, AlexaLogin, AlexaProxy\n",
        "from alexapy import AlexaAPI, AlexaLogin, AlexaProxy\n"
        "from authcaptureproxy.examples.amazon_waf import AmazonWAFInterceptor\n",
    ),
    (
        '"play_audio_en-US": "ask music assistant to play audio",',
        '"play_audio_en-US": "ask wecker music to play audio",',
    ),
    (
        '            post_path = "/alexa/auth/proxy/ap/signin/*"\n',
        '            proxy_callback_path = "/alexa/auth/proxy/*"\n',
    ),
    (
        "            proxy = AlexaProxy(login, proxy_url)\n",
        "            proxy = AlexaProxy(login, proxy_url)\n"
        "            proxy.interceptors = [AmazonWAFInterceptor()]\n",
    ),
    (
        '            mass.webserver.register_dynamic_route(post_path, proxy_handler, "POST")\n',
        '            mass.webserver.register_dynamic_route(proxy_callback_path, proxy_handler, "*")\n',
    ),
    (
        "                await auth_helper.authenticate(proxy_url)\n",
        "                await auth_helper.authenticate(proxy_url, timeout=600)\n",
    ),
    (
        '                mass.webserver.unregister_dynamic_route(post_path, "POST")\n',
        '                mass.webserver.unregister_dynamic_route(proxy_callback_path, "*")\n',
    ),
)


def apply() -> None:
    """Apply known-safe substitutions to the installed provider."""
    source = PROVIDER.read_text(encoding="utf-8")
    updated = source
    for old, new in REPLACEMENTS:
        if new in updated:
            continue
        if old not in updated:
            print("Music Assistant Alexa compatibility fix skipped: upstream changed")
            return
        updated = updated.replace(old, new, 1)
    if updated != source:
        PROVIDER.write_text(updated, encoding="utf-8")


try:
    apply()
except OSError as error:
    print(f"Music Assistant Alexa compatibility fix failed: {error}")
