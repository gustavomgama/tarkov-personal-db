# Project notes

## Python tooling

The system Python is PEP 668 externally-managed. Use the project venv:

    ~/.pyvenv-tarkov/bin/python   # or: activated via `source ~/.pyvenv-tarkov/bin/activate`
    ~/.pyvenv-tarkov/bin/pip      # to install more packages
    ~/.pyvenv-tarkov/bin/python -m venv  # existing venvs live under ~/.pyvenv-*

### Wikitext parsing

For ALL Python tasks that touch MediaWiki wikitext (e.g. files under `offlinedata/officialwiki/`, contentmodel `text/x-wiki`), use `mwparserfromhell` — never hand-rolled regex. Entrypoint:

    import mwparserfromhell
    code = mwparserfromhell.parse(wikitext)
    # code.filter_templates(...), code.filter_wikilinks(...), code.tables, etc.

Installed version: mwparserfromhell 0.7.2.