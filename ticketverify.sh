#!/bin/bash

usage() {
  cat << EOF

Generate an OCS Provider/Consumer onboarding ticket to STDOUT
USAGE: $0 [-h] <public_key_file> [<ticket_file>]

public_key_file:
    A file containing a valid RSA puiblic key.

ticket_file:
    A file containing an onboarding ticket.
    Default value is "onboarding_ticket.txt"

Example of how to generate a new private/public key pair:
  openssl genrsa -out key.pem 4096
  openssl rsa -in key.pem -out pubkey.pem -outform PEM -pubout

EOF
  echo "USAGE: $0 <public_key_file> [<ticket_file>]"
}

if [ $# == 0 ]; then
  echo "Missing argument for key file!"
  usage
  exit 1
fi

if [[ "${1}" == "-h" ]] || [[ "${1}" == "--help" ]]; then
  usage
  exit 0
fi

KEY_FILE="${1}"
if [[ ! -f "${KEY_FILE}" ]]; then
  echo "Key file '${KEY_FILE}' not found!"
  usage
  exit 1
fi

TICKET_FILE="${2:-onboarding_ticket.txt}"
if [[ ! -f "${TICKET_FILE}" ]]; then
  echo "Ticket file '${TICKET_FILE}' not found!"
  usage
  exit 1
fi

TICKET="$(cat "${TICKET_FILE}")"

IFS='.' read -ra TICKET_ARR <<< "${TICKET}"
PAYLOAD="${TICKET_ARR[0]}"
SIG="${TICKET_ARR[1]}"

SIG_FILE="$(mktemp)"
MESSAGE_FILE="$(mktemp)"

echo "${PAYLOAD}" > ${MESSAGE_FILE}
echo -n "${SIG}" | base64 -d > "${SIG_FILE}"
aws kms verify \
  --key-id alias/odf \
  --message-type RAW \
  --signing-algorithm RSASSA_PKCS1_V1_5_SHA_256 \
  --message file://${MESSAGE_FILE} \
  --signature fileb://${SIG_FILE}

rm "${SIG_FILE}"
rm "${MESSAGE_FILE}"
