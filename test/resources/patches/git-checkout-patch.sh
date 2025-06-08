#!/bin/bash

for file in /workflow/.github/workflows/*.yml; do
  token=$(cat /docker/gitserver/data/token.txt)
  TOKEN=$token yq -i '
  (
    .. | select(has("uses"))
       | select(.uses | test("actions/checkout.*"))
  ) |= (
    . * {"with": (.with // {})}
       | .with.github-server-url = "http://gitserver:3000"
       | .with.token = strenv(TOKEN)
  )
' "$file"
done