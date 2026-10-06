#!/bin/bash
# Example: Save data via Nginx Lua handler
# Requires X-Foo-Id and X-Foo-Key headers for authentication

set -e

echo "Saving data to /save/mydata..."

curl -v -X POST \
  -H "X-Foo-Id: demo" \
  -H "X-Foo-Key: jH4y7Ka81JQ8jaDc891jka9D8k3DlkM1ja8D-Zo1jwS" \
  -H "Content-Type: application/json" \
  -d '{"name":"John","age":30}' \
  http://localhost/save/mydata

echo ""
echo "Done"
