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
      #echo "components_items - $components_items"

      empty_items=0
      if [[ $components_items == "" ]] || [[ $components_items == "null" ]]; then
        empty_items=1
      fi

      if [[ $components_items_count -eq 1 ]] && [[ $empty_items -eq 1 ]]; then
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



function addChildElements() { # params kustomizationFile, componentEntries, parentElement
  kustomizationFile=$1
  parentElement=$2
  componentEntries=$3

  for componentEntry in "${componentEntries[@]}"
  do
      #TO find the length of items in the components
      #echo "Scanning file .."
      components_items=$(yq "$parentElement" "$kustomizationFile" --unwrapScalar=false)
      components_items_count=$(echo "$components_items" | wc -l)
      #echo "components_items_count - $components_items_count"
      #echo "components_items - $components_items"

      empty_items=0
      if [[ $components_items == "" ]] || [[ $components_items == "null" ]]; then
        empty_items=1
      fi
      #echo "components_items_count- $components_items_count"
      if [[ $components_items_count -eq 1 ]] && [[ $empty_items -eq 1 ]]; then
        # To add the components on empty list
        #echo "adding first element.. $componentEntry"
        #echo yq -i '.components[0]="'"$componentEntry"'"' "$kustomizationFile"  
        #echo yq -i "$parentElement"[0]='"'"$componentEntry"'"' "$kustomizationFile"  
        yq -i "$parentElement"[0]='"'"$componentEntry"'"' "$kustomizationFile"  
      else
        #echo "adding additional element.. $componentEntry"
        #yq -i '.components['"$components_items_count"']="'"$componentEntry"'"' "$kustomizationFile"
        #yq -i '.components += '"$componentEntry" "$kustomizationFile" 
        #echo yq -i '.components += "'"$componentEntry"'"' "$kustomizationFile" 
        yq -i "$parentElement"["$components_items_count"]='"'"$componentEntry"'"' "$kustomizationFile"
      fi
  done
} 

#For UNIT TEST
#kustomizationFile="$WORK_DIR/scripts/hybrid-artifacts/test-kustomization.yaml";

#componentEntries=("./components/cassandra-resources" "./components/http-proxy")
#addChildElements "$kustomizationFile" ".components" "${componentEntries[@]}"

#componentEntries=("./cassandra-data-replication.yaml")
#addChildElements "$kustomizationFile" ".resources" "${componentEntries[@]}"

#echo "adding..."
#yq -i '.spec.components.cassandra.properties.multiRegionSeedHost="'"$SEED_IP_ADDRESS"'"' "${WORK_DIR}/scripts/hybrid-artifacts/test-multi-region/patch.yaml"

function hybridPreInstallOverlaysPrepForRegionExpansion() {

  yq -i '.spec.components.cassandra.properties.multiRegionSeedHost="'"$SEED_IP_ADDRESS"'"' \
    "${WORK_DIR}/scripts/hybrid-artifacts/test-multi-region/patch.yaml"

  kpt fn eval "${WORK_DIR}/scripts/hybrid-artifacts/test-multi-region/cassandra-data-replication.yaml" \
      --image gcr.io/kpt-fn/apply-setters:v0.2.0 -- \
      SOURCE_CASSANDRA_DC_NAME="$SOURCE_CASSANDRA_DC_NAME"

  echo "Updating multi-region kustomization"
  multiRegionKustomizationFile="${WORK_DIR}/scripts/hybrid-artifacts/test-multi-region/kustomization.yaml";
  resourceEntries=("./cassandra-data-replication.yaml")
  addChildElements "$multiRegionKustomizationFile" ".resources" "${resourceEntries[@]}"
}

#hybridPreInstallOverlaysPrepForRegionExpansion;