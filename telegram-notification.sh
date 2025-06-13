#!/bin/bash

frequency=$1
date=$2
branch=$3
mongodump=$4
mongodumponetime=$5

safe_date=$(echo "$date" | sed 's/-/\\-/g')

# Telegram API FQDN
TELEGRAM_API="api.telegram.org"
# Telegram Bot token # Note: ops_bot
TELEGRAM_TOKEN="INSERT_TOKEN"
# test group
#GROUP_ID="-XXXXXXXXX"
GROUP_ID="-XXXXXXXXXXXXX"
# Supported parse mode => https://core.telegram.org/bots/api#formatting-options
PARSE_MODE="MarkdownV2"

# Escape all special characters in the string
escape_spec_chars() {
  local STRING=${1}
  local SPEC_CHARS=('-' '_' '*' '`' '!' '@' '#' '%' '&' '(' ')' '.')

  for SPEC_CHAR in "${SPEC_CHARS[@]}"; do
    if [[ ${SPEC_CHAR} == '&' ]]; then
      STRING=${STRING//'&'/%26}
      continue
    fi
    STRING=${STRING//${SPEC_CHAR}/\\${SPEC_CHAR}}
  done
  STRING=${STRING// /%20}

  echo "${STRING}"
}

# Escape special characters
HOSTNAME=$(escape_spec_chars "${HOSTNAME}")

# Use different text messages per type
if [ -n "$frequency" ]; then
  safe_date=$(echo "$date" | sed 's/-/\\-/g')
  case "$frequency" in
    "daily")
      TEXT="%F0%9F%9A%80 Daily MongoDB backup to S3 completed on $safe_date"
      ;;
    "weekly")
      TEXT="%F0%9F%9A%80 Weekly MongoDB backup to S3 completed on $safe_date"
      ;;
    "monthly")
      TEXT="%F0%9F%9A%80 Monthly MongoDB backup to S3 completed on $safe_date"
      ;;
    *)
      TEXT="Unknown backup type triggered"
      ;;
  esac
else
  case ${branch}${mongodump}${mongodumponetime} in
    "staging")
      TEXT="%F0%9F%9A%80 Deployed to staging servers successfully"
      ;;
    "production")
      TEXT="%F0%9F%9A%80 Deployed to production servers successfully"
      ;;
    "mongo")
      TEXT="%F0%9F%9A%80 Daily mongodump backup to S3 completed"
      ;;
    "onetime")
      TEXT="%F0%9F%97%BF Mongodump has been executed once"
      ;;
    *)
      echo "No known operation matched."
      exit 0
      ;;
  esac
fi

echo "Frequency: $frequency"
echo "Date: $date"
echo "Text: $TEXT"

# Send Telegram API request
curl -sSg "https://${TELEGRAM_API}/bot${TELEGRAM_TOKEN}/sendMessage?chat_id=${GROUP_ID}&parse_mode=${PARSE_MODE}&text=${TEXT}"
