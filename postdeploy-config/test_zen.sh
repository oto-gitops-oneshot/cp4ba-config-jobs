

### VARIABLES ###
ADMIN_USER_LIST='"zen_administrator_role","iaf-automation-admin","iaf-automation-analyst","iaf-automation-developer","iaf-automation-operator","zen_user_role"'
USER_LIST='"iaf-automation-analyst","iaf-automation-developer","iaf-automation-operator","zen_user_role"'

### OPENSHIFT ###
CP4BA_PROJECT_NAME="cp4ba"
TOKEN_PATH=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${TOKEN_PATH}/ca.crt
oc_token=$(cat ${TOKEN_PATH}/token)
oc_server='https://kubernetes.default.svc'
oc login $oc_server --token=${oc_token} --certificate-authority=${CACERT} --kubeconfig="/tmp/config"
zen_admin_password=$(oc get secret admin-user-details -n cp4ba -o jsonpath='{.data.initial_admin_password}' | base64 -D)
route=$(oc get route cpd -n $CP4BA_PROJECT_NAME -o jsonpath='{.spec.host}')



### ZEN ### 
token_response=$(curl -k --request POST --header "Content-Type: application/json" --data "{\"username\":\"admin\", \"password\":\"$zen_admin_password\"}" https://$route/icp4d-api/v1/authorize)

token=$(echo $token_response | jq -r '.token')

############# ADMINS #############
echo "Registering admins in Zen group cpadmins"

# Add all roles to cpadmin 
echo $ADMIN_USER_LIST
add_admin_users_response=$(curl -k --location --request POST 'https://'$route'/usermgmt/v2/groups' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$token'' \
    --data-raw '{
        "name":"cpadmins",
        "role_identifiers":['$ADMIN_USER_LIST']
        }')

# should ideally use get_Zen groups to get these fields 
admin_group_id=$(echo $add_admin_users_response | jq -r '.group_id')
admin_group_name=$(echo $add_admin_users_response | jq -r '.name')

echo "admin id: $admin_group_id"
echo "admin name: $admin_group_name"
# register ldap with zen group cpadmins
register_ldap_with_zen=$(curl -k --location --request POST 'https://'$route'/usermgmt/v2/groups/'$admin_group_id'/members' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$token'' \
    --data-raw '{
        "user_identifiers":[],
        "ldap_groups":["cn='$admin_group_name',ou=Groups,dc=cp"]
        }')
# register ldap group with zen group cpadmins - this occurs twice in apollo best i can tell. dont need this one. 
# register_ldap_with_zen=$(curl -k --location --request POST 'https://'$route'/usermgmt/v2/groups/'$admin_group_id'/members' \
#     --header 'Content-Type: application/json' \
#     --header 'Authorization: Bearer '$token'' \
#     --data-raw '{
#         "user_identifiers":[],
#         "ldap_groups":["cn='$admin_group_name',ou=Groups,dc=cp"]
#         }')

############## USERS ##############
echo "registering users in Zen group cpusers ldap"
echo $USER_LIST
add_users_response=$(curl -k --location --request POST 'https://'$route'/usermgmt/v2/groups' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$token'' \
    --data-raw '{
        "name":"cpusers",
        "role_identifiers":['$USER_LIST']
        }')

echo $add_users_response
# should ideally use get_Zen groups to get these fields 
user_group_id=$(echo $add_users_response | jq -r '.group_id')
user_group_name=$(echo $add_users_response | jq -r '.name')

echo "user id: $user_group_id"
echo "user name: $user_group_name"
# register ldap with zen group cpadmins
register_ldap_with_zen=$(curl -k --location --request POST 'https://'$route'/usermgmt/v2/groups/'$user_group_id'/members' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$token'' \
    --data-raw '{
        "user_identifiers":[],
        "ldap_groups":["cn='$user_group_name',ou=Groups,dc=cp"]
        }')


get_zen_groups=$(curl -k --location --request GET 'https://'$route'/usermgmt/v2/groups' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$token'')

echo $get_zen_groups