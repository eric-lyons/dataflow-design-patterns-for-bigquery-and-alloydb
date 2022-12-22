# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module "gcs-data" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.project_id
  name           = "data"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? module.kms[0].keys.key-gcs.id : null
  force_destroy  = true
}

module "gcs-df-tmp" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs"
  project_id     = module.project.project_id
  prefix         = var.project_id
  name           = "df-tmp"
  location       = var.region
  storage_class  = "REGIONAL"
  encryption_key = var.cmek_encryption ? module.kms[0].keys.key-gcs.id : null
  force_destroy  = true
}

module "bigquery-dataset" {
  count = local.use_bq_dataset ? 0 : 1
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/bigquery-dataset"
  project_id = module.project.project_id
  id         = "datalake"
  location   = var.region
  encryption_key = var.cmek_encryption ? module.kms[0].keys.key-bq.id : null
}
