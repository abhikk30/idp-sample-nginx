# idp-sample-nginx

Sample static-page app onboarded end-to-end into the lw-idp dev cluster.

- **Source** lives here.
- **CI:** Jenkins (`sample-nginx` pipeline) builds via kaniko on every
  push to `main` and rewrites `chart/values.yaml` `image.tag` with the
  short SHA. The bump commit uses `[skip ci]` to avoid loops.
- **CD:** Argo CD watches `chart/` and auto-syncs to the
  `sample-nginx` namespace.
- **URL:** http://sample.lw-idp.local/

## Make a change

1. Edit `html/index.html` (or anything else).
2. Commit + push to `main`.
3. Watch Jenkins → Argo CD → reload the page.
4. The Build SHA shown on the page should now match the new commit.

## Rotate the GitHub PAT used for tag bumps

See `lw-idp/docs/runbooks/sample-nginx-onboarding.md` (in the lw-idp repo).
