/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


gke_cluster = {
  name                      = "hybrid-cluster"
  location                  = "us-central1"
  master_authorized_ranges  = {
    "internet" = "0.0.0.0/0"
  }
  master_ip_cidr            = "192.168.0.0/28"
  region                    = "us-central1"
}