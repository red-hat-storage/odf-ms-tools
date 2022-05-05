#!/bin/bash

usage() {
  cat << EOF

Generate an OCS Provider/Consumer onboarding ticket to STDOUT
USAGE: $0 [-h]

EOF
}

if [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]]; then
  usage
  exit 0
fi

# In case the system doesn't have uuidgen, fall back to /dev/urandom
NEW_CONSUMER_ID="$(uuidgen || (tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 36 | head -n 1) || echo "00000000-0000-0000-0000-000000000000")"
EXPIRATION_DATE="$(( $(date +%s) + 172800 ))"

declare JSON
add_var() {
  if [[ -n "${JSON}" ]]; then
    JSON+=","
  fi

  JSON+="$(printf '"%s":"%s"' "${1}" "${2}")"
}

## Add ticket values here
add_var "id" "${NEW_CONSUMER_ID}"
add_var "expirationDate" "${EXPIRATION_DATE}"

PAYLOAD="$(echo -n "{${JSON}}" | base64 | tr -d "\n")"
MESSAGE_FILE="$(mktemp)"

echo -n "{${JSON}}" | base64 > ${MESSAGE_FILE}
SIG="$(aws kms sign \
  --key-id alias/odf \
  --message-type RAW \
  --signing-algorithm RSASSA_PKCS1_V1_5_SHA_256 \
  --output text \
  --query Signature \
  --message fileb://${MESSAGE_FILE} )"
cat <<< "${PAYLOAD}.${SIG}"
rm "${MESSAGE_FILE}"
