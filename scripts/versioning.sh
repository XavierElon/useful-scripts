#!/bin/bash

getCurrentVersion () {
    currentversion=$(aws ssm get-parameter --name PARAMETER_STORE_VARIABLE_NAME --region 'us-gov-west-1' | sed -n -e 's/.*Value\"[^\"]*//p' | sed -n -e 's/[\"\,]//gp')
    echo 'Current version: '$currentversion
    local currentversion
}

getUpdatedVersion () {
    updatedversion=$(aws ssm get-parameter --name PARAMETER_STORE_VARIABLE_NAME --region 'us-gov-west-1' | sed -n -e 's/.*Value\"[^\"]*//p' | sed -n -e 's/[\"\,]//gp')
    echo 'Updated version: ' $updatedversion | tr -d '\n'
}

putUpdatedVersion () {
    aws ssm put-parameter --name PARAMETER_STORE_VARIABLE_NAME --value $1 --type "String" --overwrite > /dev/null
    getUpdatedVersion
}

getMajor () {
    major=$(printf $currentversion | grep -o ^[0-9]* | tr -d '\n')
    echo $major
}

getMinor () {
    minor=$(printf $currentversion | grep -o ^[0-9]*\\.[0-9]* | tr -d '\n' | tail -c 1)
    echo $minor
}

getPatch () {
    patch=$(printf $currentversion | grep -o [0-9]*$ | tr -d '\n')
    echo $patch
}

incrementMajor () {
    major=$(($1+1))
    echo $major
}

incrementMinor () {
    minor=$(($1+1))
    echo $minor
}

incrementPatch () {
    patch=$(($1+1))
    echo $patch
}

readUserInput () {
    echo 'Please enter version number in the format [MAJOR].[MINOR].[PATCH]'
    getCurrentVersion
    read -p 'New version: ' versionnumber
}

isVersionNumber () {
    SEMVER_REGEX="^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(\\-[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?(\\+[0-9A-Za-z-]+(\\.[0-9A-Za-z-]+)*)?$"
    versionnumber=$1
    while ! [[ $versionnumber =~ ${SEMVER_REGEX} ]]
    do
        readUserInput
    done
}

listCommands () {
    echo '  Options:'
    echo '- patch: increment patch by 1'
    echo '- major: increment major version by 1'
    echo '- minor: increment minor version by 1'
    echo '- edit: set a new version. Must be in format [MAJOR].[MINOR].[PATCH]'
    echo '- [-h|--help|help]: list all commands'
}

getAll () {
    getCurrentVersion currentversion
    major=$(getMajor "$currentversion")
    minor=$(getMinor "$currentversion")
    patch=$(getPatch "$currentversion")
}

main () {
    getAll
    if [ "$1" = 'major' ]; then
        minor='0'
        patch='0'
        updatedmajor=$(incrementMajor "$major")
        updatedversion=$updatedmajor.$minor.$patch
        echo 'Incrementing major...'
        putUpdatedVersion $updatedversion
    elif [ "$1" = 'minor' ]; then
        patch='0'
        updatedminor=$(incrementMinor "$minor")
        updatedversion=$major.$updatedminor.$patch
        echo 'Incrementing minor...'
        putUpdatedVersion $updatedversion
    elif [ "$1" = 'patch' ]; then
        updatedpatch=$(incrementPatch "$patch")
        updatedversion=$major.$minor.$updatedpatch
        echo 'Incrementing patch...'
        putUpdatedVersion $updatedversion
    elif [ "$1" = 'edit' ]; then
        readUserInput
        updatedversion="$versionnumber"
        isVersionNumber $updatedversion
        updatedversion="$versionnumber"
        echo 'Updating version...'
        putUpdatedVersion $updatedversion
    elif [ "$1" = 'help' ] || [ "$1" = '--help' ] || [ "$1" = '-h' ]; then
        listCommands
    else
        echo 'Please enter a valid argument for versioning.'
        listCommands
    fi
}

main $1
