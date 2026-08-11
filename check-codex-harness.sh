#!/bin/sh
# Temporary diagnostic: check whether the bundled Codex harness restricts
# itself to the openai provider (i.e. can it run custom providers like neonx).
HARNESS_JS="/app/dist/harness-DcScoxo-.js"
ls -la "$HARNESS_JS" 2>/dev/null || echo "harness js not found, searching..."
[ -f "$HARNESS_JS" ] || HARNESS_JS=$(ls /app/dist/harness-*.js 2>/dev/null | head -1)
echo "Using: $HARNESS_JS"

echo "--- openai provider checks ---"
grep -c 'openai' "$HARNESS_JS" || true
grep -o 'provider[A-Za-z]* === "openai"' "$HARNESS_JS" | sort | uniq -c || true
grep -o '"openai"' "$HARNESS_JS" | wc -l

echo "--- claim/support logic ---"
grep -o 'claim[A-Za-z]*' "$HARNESS_JS" | sort -u | head
grep -o 'supports[A-Za-z]*' "$HARNESS_JS" | sort -u | head

echo "--- model resolution hints ---"
grep -o 'modelRef[A-Za-z]*' "$HARNESS_JS" | sort -u | head
grep -n 'Runtime: OpenAI Codex' "$HARNESS_JS" | head -2

echo "--- any custom provider handling ---"
grep -o 'model_providers' "$HARNESS_JS" | head -2
grep -o 'CODEX_HOME' "$HARNESS_JS" | wc -l
