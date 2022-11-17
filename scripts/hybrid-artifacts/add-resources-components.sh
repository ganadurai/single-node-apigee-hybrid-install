#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function addComponents() { # params kustomizationFile, componentEntries
  kustomizationFile=$1
  componentEntries=$2

  for componentEntry in "${componentEntries[@]}"
  do
      #TO find the length of items in the components
      #echo "Scanning file .."
      components_items=$(yq '.components' "$kustomizationFile" --unwrapScalar=false)
      components_items_count=$(echo "$components_items" | wc -l)
      #echo "components_items_count - $components_items_count"
      if [[ $components_items_count -eq 1 ]] && [[ $components_items == "null" || $components_items == "" ]]; then
        # To add the components on empty list
        #echo "adding first element.. $componentEntry"
        yq -i '.components[0]="'"$componentEntry"'"' "$kustomizationFile"  
      else
        #echo "adding additional element.. $componentEntry"
        #yq -i '.components['"$components_items_count"']="'"$componentEntry"'"' "$kustomizationFile"
        #yq -i '.components += '"$componentEntry" "$kustomizationFile" 
        yq -i '.components += "'"$componentEntry"'"' "$kustomizationFile" 
      fi
  done
}

function addComponentsNew() { # params kustomizationFile, componentEntries
  kustomizationFile=$1
  componentEntries=$2

  for componentEntry in "${componentEntries[@]}"
  do
      #TO find the length of items in the components
      #echo "Scanning file .."
      components_items=$(yq '.components' "$kustomizationFile" --unwrapScalar=false)
      components_items_count=$(echo "$components_items" | wc -l)
      echo "components_items_count - $components_items_count"
      echo "components_items=$components_items"
      echo "components_items length=${#components_items[@]}"
      echo "components_items[0]=${components_items[0]}"
      if [[ $components_items_count -eq 1 ]] && [[ $components_items == "null" || $components_items == "" ]]; then
        # To add the components on empty list
        echo "adding first element.. $componentEntry"
        yq -i '.components[0]="'"$componentEntry"'"' "$kustomizationFile"  
      else
        echo "adding additional element.. $componentEntry"
        #yq -i '.components['"$components_items_count"']="'"$componentEntry"'"' "$kustomizationFile"
        #yq -i '.components += '"$componentEntry" "$kustomizationFile" 
        yq -i '.components += "'"$componentEntry"'"' "$kustomizationFile" 
      fi
  done
}

function simpleTest() {
  #TO find the length of items in the components
  components_items=$(yq '.components' "$WORK_DIR/test-kustomization.yaml")
  components_items_count=$(echo "$components_items" | wc -l)

  echo "$components_items_count"
  if [[ $components_items_count -eq 1 ]] && [[ $components_items == "null" ]]; then
    # To add the components on empty list
    echo "adding"
    yq -i '.components[0]="./components/cassandra-resources"' "$WORK_DIR/test-kustomization.yaml"  
  else
    yq -i '.components['"$components_items_count"']="./components/http-proxy"' "$WORK_DIR/test-kustomization.yaml"
  fi
}

#kustomizationFile="$WORK_DIR/test-kustomization.yaml";
#componentEntries=("./components/cassandra-resources" "./components/http-proxy")
#addComponents "$kustomizationFile" "${componentEntries[@]}"
