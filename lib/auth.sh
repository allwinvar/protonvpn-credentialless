#auth.sh

create_session(){
session_response=$(curl 'https://vpn-api.proton.me/auth/v4/sessions' \
  -X POST --cookie-jar cookie.jar \
  -H 'User-Agent: PVPN/5.18.75.1 (Android 12; Google Pixel 6)' \
  -H 'x-pm-appversion: android-vpn@5.18.75.1-dev+play' \
  -H 'x-pm-apiversion: 4' \
  -H 'Accept: application/vnd.protonmail.v1+json' \
  -H 'Content-Type: application/json' \
  --data-raw '{
    "Payload": {
      "vpn-android-v4-challenge-0": {
        "type": "me.proton.core.challenge.data.frame.ChallengeFrame.Device",
        "v": "5.18.75.1",
        "appLang": "en",
        "timezone": "America/New_York",
        "deviceName": -148477506,
        "regionCode": "US",
        "timezoneOffset": 240,
        "isJailbreak": false,
        "preferredContentSize": "1.0",
        "storageCapacity": 128.0,
        "isDarkmodeOn": false,
        "keyboards": [
          "com.google.android.inputmethod.latin"
        ]
      }
    }
  }'
)

umask 077

x_pm_uid=$(echo "$session_response" | jq -r '.UID')
access_token=$(echo "$session_response" | jq -r '.AccessToken')
session_id=$(awk '$6 == "Session-Id" { print $7; exit }' cookie.jar)

jq -n \
  --arg uid "$x_pm_uid" \
  --arg access_token "$access_token" \
  --arg session_id "$session_id" \
  '{UID: $uid, AccessToken: $access_token, SessionId: $session_id}' \
  > session_credentials.json

chmod 600 session_credentials.json
}


#load them later
#x_pm_uid=$(jq -r '.UID' session_credentials.json)
#access_token=$(jq -r '.AccessToken' session_credentials.json)
#session_id=$(jq -r '.SessionId' session_credentials.json)



get_credentialless_token(){
    x_pm_uid=$(jq -r '.UID' session_credentials.json)

    credentialless=$(curl ${CURL_VERBOSE:+-v} ${CURL_NO_SILENT:--sS} \
        --fail --connect-timeout 10 --retry 3 \
        -X POST \
        -H 'User-Agent: PVPN/5.18.75.1 (Android 12; Google Pixel 6)' \
        -H 'x-pm-appversion: android-vpn@5.18.75.1-dev+play' \
        -H 'x-pm-apiversion: 4' \
        -H 'Accept: application/vnd.protonmail.v1+json' \
        -H 'Content-Type: application/json' \
        -H "x-pm-uid: $x_pm_uid" \
        -H "Authorization: Bearer $access_token" \
        --data-raw '{"Payload":{"vpn-android-v4-challenge-0":{"type":"me.proton.core.challenge.data.frame.ChallengeFrame.Device","v":"5.18.75.1","appLang":"en","timezone":"America/New_York","deviceName":-148477506,"regionCode":"US","timezoneOffset":240,"isJailbreak":false,"preferredContentSize":"1.0","storageCapacity":128.0,"isDarkmodeOn":false,"keyboards":["com.google.android.inputmethod.latin"]}}}' \
        'https://vpn-api.proton.me/auth/v4/credentialless')

    if printf '%s' "$credentialless" |
    jq -e '.Code == 1000 and (.AccessToken | type == "string" and length > 0)' >/dev/null
    then
        echo "Guest login successful"
        credentialless_access_token=$(printf '%s' "$credentialless" | jq -r '.AccessToken')

        umask 077
        tmp_file=$(mktemp session_credentials.json.XXXXXX) || return 1
        if jq --arg token "$credentialless_access_token" \
            '. + {CredentiallessAccessToken: $token}' \
            session_credentials.json > "$tmp_file"; then
            chmod 600 "$tmp_file"
            mv "$tmp_file" session_credentials.json
        else
            rm -f "$tmp_file"
            echo "Could not save credentialless token" >&2
            return 1
        fi
    else
        echo "Guest login failed" >&2
        return 1
    fi
}   

#load later with
#credentialless_access_token=$(jq -r '.CredentiallessAccessToken' session_credentials.json)

