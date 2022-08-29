
#!/bin/bash
set +e

function configure_zen { 
        ### VARIABLES ###
        ADMIN_USER_LIST='"zen_administrator_role","iaf-automation-admin","iaf-automation-analyst","iaf-automation-developer","iaf-automation-operator","zen_user_role"'
        USER_LIST='"iaf-automation-analyst","iaf-automation-developer","iaf-automation-operator","zen_user_role"'

        zen_admin_password=$(oc get secret admin-user-details -n cp4ba -o jsonpath='{.data.initial_admin_password}' | base64 --decode)
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

}

function configure_ier { 
    echo "Configuring IER"
    
    zen_admin_password=$(oc get secret admin-user-details -n cp4ba -o jsonpath='{.data.initial_admin_password}' | base64 --decode)
    cpd_route=$(oc get route cpd -n $CP4BA_PROJECT_NAME -o jsonpath='{.spec.host}')

    #####################################################
    ######## PERFORM TEMPLATE SUBSTITUTIONS #############
    #####################################################
    echo "Performing file templating"
    # Variables to be replaced
    ## cp4ba project name  above ## 
    cp4ba_output_directory="cp4ba"
    apps_endpoint_domain=$(oc --namespace openshift-ingress-operator get ingresscontrollers -o jsonpath='{$.items[0].status.domain}')
    universal_password=$(oc get secret universal-password -n cp4ba -o jsonpath='{.data.universalPassword}' | base64 --decode)

    tar xvf ierconfig.tar.gz

    ## Confg.ini 
    filepath="configure/configuration/config.ini"

    sed -i -e 's/{{ cp4ba_output_directory }}/'$cp4ba_output_directory'/g' $filepath
    sed -i -e 's/{{ universal_password }}/'$universal_password'/g' $filepath
    sed -i -e 's/{{ cp4ba_project_name }}/'$CP4BA_PROJECT_NAM'/g' $filepath
    sed -i -e 's/{{ apps_endpoint_domain }}/'$apps_endpoint_domain'/g' $filepath

    cat $filepath

    ## configureworkflows.xml 
    filepath="configure/profiles/configureWorkflows.xml"

    sed -i -e 's/{{ cp4ba_output_directory }}/'$cp4ba_output_directory'/g' $filepath
    sed -i -e 's/{{ universal_password }}/'$universal_password'/g' $filepath
    sed -i -e 's/{{ cp4ba_project_name }}/'$CP4BA_PROJECT_NAM'/g' $filepath
    sed -i -e 's/{{ apps_endpoint_domain }}/'$apps_endpoint_domain'/g' $filepath

    cat $filepath

    #createMarkingSetsAndAddOns
    filepath="configure/profiles/createMarkingSetsAndAddOns.xml"

    sed -i -e 's/{{ cp4ba_output_directory }}/'$cp4ba_output_directory'/g' $filepath
    sed -i -e 's/{{ universal_password }}/'$universal_password'/g' $filepath
    sed -i -e 's/{{ cp4ba_project_name }}/'$CP4BA_PROJECT_NAM'/g' $filepath
    sed -i -e 's/{{ apps_endpoint_domain }}/'$apps_endpoint_domain'/g' $filepath

    cat $filepath

    # environment objects store
    filepath="configure/profiles/environmentObjectStoreConfiguration.xml"
    sed -i -e 's/{{ cp4ba_output_directory }}/'$cp4ba_output_directory'/g' $filepath
    sed -i -e 's/{{ universal_password }}/'$universal_password'/g' $filepath
    sed -i -e 's/{{ cp4ba_project_name }}/'$CP4BA_PROJECT_NAM'/g' $filepath
    sed -i -e 's/{{ apps_endpoint_domain }}/'$apps_endpoint_domain'/g' $filepath

    cat $filepath

    #####################################################
    ########### ACCESS TOKEN AND API CALLS ##############
    #####################################################

    get_iam_token=$(curl -k --location --request POST 'https://cp-console.'$apps_endpoint_domain'/idprovider/v1/auth/identitytoken' \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'scope=openid' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'username=cpadmin' \
    --data-urlencode 'password='$universal_password'')

    iam_access_token=$(echo $get_iam_token | jq -r '.access_token')
    # echo $iam_access_token

    exchange_iam_for_zen=$(curl -k --location --request GET 'https://cpd-'$CP4BA_PROJECT_NAME'.'$apps_endpoint_domain'/v1/preauth/validateAuth' \
    --header 'iam-token: '$iam_access_token'' \
    --header 'username: cpadmin')

    # echo $exchange_iam_for_zen

    zen_access_token=$(echo $exchange_iam_for_zen | jq -r '.accessToken')

    echo "creating core modules"
    ## It appears this endpoint is unavailable at the time of writing this script. Will need to investigate. 
    create_core_modules=$(curl -k --location --request POST 'https://cpd-'$CP4BA_PROJECT_NAME'.'$apps_endpoint_domain'/content-services-graphql/graphql' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer '$zen_access_token'' \
    --data-raw 'query: | mutation CreateCodeModulesFolder {createFolder(repositoryIdentifier: "FPOS", folderProperties: {name: "CodeModules", parent: {identifier: "/"} }) {id} }')

    echo $create_core_modules

    echo "Running configuration tasks"
    configure/configmgr_cl execute -task createMarkingSetsAndAddOns
    configure/configmgr_cl execute -task configureFPOS
    configure/configmgr_cl execute -task configureROS
    configure/configmgr_cl execute -task configureWorkflows
    configure/configmgr_cl execute -task transferWorkflows

    # filesystem cleanup
    rm -rf CommonFiles/
    rm -rf configure/
    rm -rf Plugins/
    rm -rf Workflows/
    rm version.txt

  
    

}

function configure_ier_tm {
    echo "Configuring IER-TM"

    tm_pod_name=$(oc get pods -l app=icp4adeploy-tm-deploy -o jsonpath='{.items[0].metadata.name}')
    echo "copying additional jar files to /opt/ibm/extTM in $tm_pod_name"
    oc cp ier/AdditionalJars.tar.gz  "$tm_pod_name:/tmp/AdditionalJars.tar.gz" -n $CP4BA_PROJECT_NAME
    oc exec $tm_pod_name -it -- tar xvf /tmp/AdditionalJars.tar.gz -C /opt/ibm/extTM//

    echo "Bouncing tm pod"

    # filesystem cleanup
    oc exec $tm_pod_name rm /tmp/AdditionalJars.tar.gz -n $CP4BA_PROJECT_NAME

    # depending on how this works it might be better practice to scale the deployment to 0 and then scale back up. 
    oc delete pod $tm_pod_name -n $CP4BA_PROJECT_NAME

    configure_tm
}

function configure_tm { 
    echo -n "Configuring TM"


}
