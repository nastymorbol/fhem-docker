#!/bin/bash

#echo $(cat ENV_FILE)

#export BASE_IMAGE="mcr.microsoft.com/dotnet/core/aspnet"
#export BASE_IMAGE_TAG="3.1"
# Microsoft uses debian:buster-slim

export BASE_IMAGE="debian"
export BASE_IMAGE_TAG="buster-slim"
export IMAGE_LAYER_SYS_EXT="0" 
export IMAGE_LAYER_PERL_EXT="0" 
export IMAGE_LAYER_DEV="0" 
export IMAGE_LAYER_PERL_CPAN="0"
export IMAGE_LAYER_PERL_CPAN_EXT="0"
export IMAGE_LAYER_PYTHON="0" 
export IMAGE_LAYER_PYTHON_EXT="0"
export IMAGE_LAYER_NODEJS="0"
export IMAGE_LAYER_NODEJS_EXT="0" 

function print_env () {
    while IFS='=' read -r -d '' n v; do 
        [[ $n =~ ^_.* ]] && continue
        [[ $n =~ ^PATH.* ]] && continue
        [[ $n =~ ^MAN.* ]] && continue
        [[ $n =~ ^POST.* ]] && continue
        [[ $n =~ .*TERM.* ]] && continue
        [[ $n =~ .*TMP.* ]] && continue
        [[ $n =~ .*SECURITY.* ]] && continue
        [[ $n =~ .*DISPLAY.* ]] && continue
        [[ $n =~ .*SHELL.* ]] && continue
        [[ $n =~ .*GIT.* ]] && continue
        [[ $v =~ .*/usr/local.* ]] && continue
        #[[ $v =~ .*\S.* ]] && continue
        printf "%s %s=%s " "--build-arg" "$n" "$v";        
    done < <(env -0)
}

function print_env2 () {
    printf "%s %s=%s " "--build-arg" "BASE_IMAGE" "$BASE_IMAGE";
    printf "%s %s=%s " "--build-arg" "BASE_IMAGE_TAG" "$BASE_IMAGE_TAG";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_SYS_EXT" "$IMAGE_LAYER_SYS_EXT";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_PERL_EXT" "$IMAGE_LAYER_PERL_EXT";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_DEV" "$IMAGE_LAYER_DEV";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_PERL_CPAN" "$IMAGE_LAYER_PERL_CPAN";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_PERL_CPAN_EXT" "$IMAGE_LAYER_PERL_CPAN_EXT";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_PYTHON" "$IMAGE_LAYER_PYTHON";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_PYTHON_EXT" "$IMAGE_LAYER_PYTHON_EXT";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_NODEJS" "$IMAGE_LAYER_NODEJS";
    printf "%s %s=%s " "--build-arg" "IMAGE_LAYER_NODEJS_EXT" "$IMAGE_LAYER_SYS_EXT";
}

print_env2;
echo
echo
echo "--- Docker Login\n"
docker login
echo
echo "--- Start BUILD\n"
#docker buildx build $(print_env2) --platform linux/amd64,linux/arm/v7 -t nastymorbol/fhem:dotnet --push .
# ARM64 derzeit nicht benötigt
#linux/arm64 
docker build $(print_env2) -t nastymorbol/fhem:dotnet .
docker run -it --rm --name fhem-test -p "8083:8083" -v "$(pwd)/../fhem-dev/:/opt/fhem/" nastymorbol/fhem:dotnet

rm -r "$(pwd)/../fhem-dev"