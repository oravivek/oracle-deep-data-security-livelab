# Rebuild the lab deliverables

The Markdown pages referenced by `workshops/livelabs/manifest.json` and the
executable files are the sources of truth. No code listings are maintained
separately in Word. Run build commands from the project root.

## Preview

Use Node.js 20 or later and a separate tooling directory:

```bash
npm install --prefix /path/to/livelabs-preview-tools marked@17.0.5
node tools/build-preview.mjs /path/to/livelabs-preview-tools/node_modules/marked/lib/marked.esm.js
```

## Word guide

Use a separate build environment or an environment with python-docx available:

```bash
python -m pip install -r tools/requirements-build.txt
python tools/build_word.py
```

The builder includes every workshop page and full executable SQL, Python,
tests and runtime configuration listing. It checks that source listings survive
unchanged in the DOCX. The document is written under `docs/`.
Render the result to PDF/page images using your document QA tools and review
every page before distribution. The released version was rendered and inspected
with the bundled document renderer.

## Verification and ZIP

Run application checks in the configured lab Python environment, update the
release verification record, and rebuild checksums after all content changes:

```bash
python -m unittest discover -s tests -v
python tools/validate_workshop.py --release --write-checksums
python tools/validate_workshop.py --release --verify-checksums
python tools/package_lab.py --output ../Oracle_Autonomous_Database_26ai_DDS_LiveLab.zip
```

Do not package by recursively zipping the working directory. The explicit
inventory excludes config.env, wallets, .local, .git, environments, downloaded
models and the downloads directory. `SHA256SUMS.txt` covers the payload files
other than itself. The ZIP has its own adjacent SHA256 file when published.

The SQL target file must contain the placeholder CHANGE_ME_PDB in a release.
Each participant edits it for their own database after extraction. Never run
cleanup solely to test a documentation or packaging change on an active demo.
