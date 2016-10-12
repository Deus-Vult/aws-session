if [ -e "/tmp/aws-token" ]; then
  export AWS_SECURITY_TOKEN=$(</tmp/aws-token)
fi

contains () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
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
    unset AWS_SECURITY_TOKEN
  fi
  
  # TO-DO: Shorten lines
  # TO-DO: Sometimes fails (seems to be for old tokens)
  output="$(aws sts get-session-token --duration-seconds ${duration} --serial-number $MFA_DEVICE --token-code $1)"
  
  if [[ $? == 0 ]]; then
    export AWS_ACCESS_KEY_ID=$(python -c "import json,sys;text=json.load(sys.stdin);print text['Credentials']['AccessKeyId'];" <<< ${output})
    export AWS_SECRET_ACCESS_KEY=$(python -c "import json,sys;text=json.load(sys.stdin);print text['Credentials']['SecretAccessKey'];" <<< ${output})
    export AWS_SECURITY_TOKEN=$(python -c "import json,sys;text=json.load(sys.stdin);print text['Credentials']['SessionToken'];" <<< ${output})
  else
    echo "Failed to create AWS session"
    return 1
  fi
  
  # TO-DO: Clear tmp file
  # Look into a way to schedule or run a find --delete command at the start
  echo "$AWS_SECURITY_TOKEN" > /var/tmp/aws-token
  echo "AWS session active for ${duration} seconds"
}

export -f aws-session
