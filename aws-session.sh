if [ -e "/var/tmp/aws-token" ]; then
  IFS="," read access_id access_key token timestamp < "/var/tmp/aws-token"
  
  if [[ $timestamp -le $(date +%s) ]]; then
    export AWS_ACCESS_KEY_ID=$access_id
    export AWS_SECRET_ACCESS_KEY=$access_key
    export AWS_SECURITY_TOKEN=$token
    export AWS_TIMESTAMP=$timestamp
  fi
fi

# Utility function that checks if an array contains a value.

contains() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# Function to cause a file to be removed once the sleep time has
# elapsed, even if the terminal it was called from is closed.
# Intended usage looks like this:
#
# selfdestruct <file> <duration> & disown

selfdestruct() {
  if [ $# != 2 ]; then
    echo "$0 <file> <duration>"
    exit 1
  fi
  
  if [ -e "$1" ]; then
    sleep $2
    IFS="," read access_id access_key token timestamp < "$1"

    delta=$(( $(date +%s)+$2 ))
    if [[ delta -ge $timestamp ]]; then
      rm $1
    fi
  fi
}

function aws-session {
  # TO-DO: Use a case statement check for arguments?
  # TO-DO: Add an argument for token duration
  if $(contains "-h" $@) || $(contains "--help" $@); then
    echo "Usage: aws-session [CODE] [-h|--help|-o]"
    echo "-o | Overrides existing key (does not delete old one)"
    return 0
  fi
  
  if [[ -z "$MFA_DEVICE" ]]; then
    printf "Enter MFA device: "
    read -r MFA
    export MFA_DEVICE="$MFA"
    echo "export MFA_DEVICE=${MFA}" >> ~/.bashrc
    echo "MFA device registered, run the command again"
    return 0
  fi
  
  # TO-DO: Validate that this seems to be a token code
  if [ -z "$1" ]; then
    echo "Requires a token code"
    return 1
  fi
  
  token_code="$1"
  duration="3600"
  
  contains "-o" $@ && unset AWS_SECURITY_TOKEN
  
  if [[ -n "$AWS_SECURITY_TOKEN" ]]; then
    echo "Security token already set"
    return 1
  else
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SECURITY_TOKEN
    unset AWS_TIMESTAMP
  fi
  
  # TO-DO: Shorten lines
  output="$(aws sts get-session-token --duration-seconds ${duration} --serial-number $MFA_DEVICE --token-code $1)"
  
  # TO-DO: Investigate if this fucks up for some security keys
  if [[ $? == 0 ]]; then
    export AWS_ACCESS_KEY_ID=$(python -c "import json,sys;text=json.load(sys.stdin);print text['Credentials']['AccessKeyId'];" <<< ${output})
    export AWS_SECRET_ACCESS_KEY=$(python -c "import json,sys;text=json.load(sys.stdin);print text['Credentials']['SecretAccessKey'];" <<< ${output})
    export AWS_SECURITY_TOKEN=$(python -c "import json,sys;text=json.load(sys.stdin);print text['Credentials']['SessionToken'];" <<< ${output})
  else
    echo "Failed to create AWS session"
    return 1
  fi
  
  echo "$AWS_ACCESS_KEY_ID,$AWS_SECRET_ACCESS_KEY,$AWS_SECURITY_TOKEN,$(date +%s)" > /var/tmp/aws-token
  selfdestruct "/var/tmp/aws-token" $duration & disown
  echo "AWS session active for ${duration} seconds"
}

export -f aws-session
