# Welcome to the STRATUS OUCCS PoC Repository!
This repository is for the Oracle Utilities Customer Cloud Service (OUCCS) PoC (proof-of-concept) build and deployment release

## Directories
- `.github\workflows` - This is where the Github Action workflows are defined
- `environment-config` - This is where the specific OUCCS environment configurations are defined
- `scripts` - This is where workflow executable scripts are located

## Files
- `.github\workflows\build-release-workflow.yml` - The specific Github Action workflow for the build release
- `.github\workflows\deployment-release-workflow.yml` - The specific Github Action workflow for the deployment of the release
- `environment-config\CCS-SANDBOX.json` - The specific OUCCS environment configuration file of the AEP Sandbox environment **(will be decommissioned on 31/Jan)**
- `scripts\runCMABatch.sh` - A shell script that runs Oracle Utilities CMA batch jobs
- `scripts\runCreateMigrationDSExport.sh` - A shell script that creates the migration data set export record in OUCCS
- `scripts\runCreateMigrationDSImport.sh` -  A shell script that creates the migration data set import record in OUCCS
- `pom.xml` - A pom file used by Maven to build the OUCCS release
- `README.md` - The repository documentation/wiki
- `zip-resources.xml` - An xml file used to define the zip assembly of the OUCCS release

## Secrets
These secrets are used by the build and deployment workflows

- `AEP_OUCCS_SBX_REST_APIS_URL` - Define the OUCCS environment REST API url
```
example: https://xx.utilities-cloud.oracleindustry.com/xxxxxx/dev/ccs/rest/apis
```

- `AEP_OUCCS_SBX_SQL_REST_URL` - Define the OUCCS environment SQL REST url
```
example: https://xx.utilities-cloud.oracleindustry.com/xxxxxx/dev/ccs/sql/rest
```

- `AEP_OUCCS_SBX_API_TOKEN` - Define the OUCCS environment API Token
**(please change this secret to the OUCCS DevOps user)**
```
example: jjfranco@xx.com:xxxxxxxx
```

- `AEP_OCI_DEVOPSUSER` - Define the OCID for the OCI user
```
example: ocid1.user.oc1..aaaaaaaaxxxxxxxxx
```

- `AEP_OCI_DEVOPSUSER_FINGERPRINT` - Define the OCI user fingerprint
```
example: 12:xx:34:xx56:xx
```

- `AEP_OCI_DEVOPSUSER_APIKEY` - Define the OCI user private key
```
-----BEGIN RSA PRIVATE KEY-----
xxxxxxxxxxxxxxxhodlbtcxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxhodlbtcxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxhodlbtcxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxhodlbtcxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxhodlbtcxxxxxxxxxxxxxxxxxxxx
-----END RSA PRIVATE KEY-----
```

- `AEP_OCI_TENANCY` - Define the OCID of OCI tenancy
```
example: ocid1.tenancy.oc1..aaaaaaaaxxxxxxxxx
```

- `AEP_OCI_REGION` - Define the OCI region
```
example: us-ashburn-1
```

- `AEP_OCI_SBX_SHARED_COMPARTMENT` - Define the OCID for the shared compartment
```
example: ocid1.compartment.oc1..aaaaaaaaxxxxxxxxx
```

- `AEP_OCI_STORAGE_NAMESPACE` - Define the OCI storage namespace
```
example: xxxhodlbtcxxx
```

- `JJFRANCO_GA_TOKEN` - Define the Github Action Token for the DevOps user 
**(please change this secret to the Github DevOps user)**
```
example: xxx_zxcvbnmsdfghjkl
```

## Workflows
This OUCCS PoC includes 2 Github Action workflows
- The Build Release Workflow
- The Deployment Release Workflow

### Build Release Workflow
Required Input Parameters:
- `Target Build Environment` - Select the target OUCCS environment where to run the configuration export
- `Migration Request ID` - Select the migration request ID to use for the configuration export

This Github workflow will do the following:
1. Spin up a virtual environment (Ubuntu) where it will run the build
2. Build and download the following Github Action repositories:
   - `actions/checkout@v2` - This is used for cloning/checking-out the Git repository
   - `sergeysova/jq-action@v2` - This is used for running JSON queries/parsing (jq)
   - `bytesbay/oci-cli-action@v1.0.2` - This is used for the Oracle Cloud Infrastructure (OCI) CLI
   - `actions/create-release@v1` - This is used for creating release in Github
   - `actions/upload-release-asset@v1` - This is used for uploading the release in Github
3. Retrieve the environment configurations defined in each of the target OUCCS environment JSON files
4. Create a migration data set export in the target OUCCS environment
5. Run maven build and create the release
6. Upload and tag the release in the repository
7. Delete the Export CMA file in the target OUCCS environment export CMA bucket
8. Perform post GIT checkout and cleanup

### Deployment Release Workflow
Required Input Parameters:
- `Target Environment` - Select the target OUCCS environment where to run the configuration export
- `Target Release` - Select the target release to deployment in the target OUCCS environment (configuration import)
    - The default option is `LATEST` - this will retrieve the latest available OUCCS release in the `main` branch
    - You can also manually input a target release (ex. build-YYMM.XX)
      - There is a logic in this workflow wherein it validates if the target release exists or not

This Github workflow will do the following:
1. Spin up a virtual environment (Ubuntu) where it will run the build
2. Build and download the following Github Action repositories:
   - `actions/checkout@v2` - This is used for cloning/checking-out the Git repository
   - `sergeysova/jq-action@v2` - This is used for running JSON queries/parsing (jq)
   - `bytesbay/oci-cli-action@v1.0.2` - This is used for the Oracle Cloud Infrastructure (OCI) CLI
   - `dsaltares/fetch-gh-release-asset@master` - This is used for retrieving the target release in the repository
3. Retrieve and validate the `Target Release` provided
4. Retrieve the environment configurations defined in each of the target OUCCS environment JSON files
5. Download the target release from the repository
6. Upload the target release to the target OUCCS environment import CMA bucket
7. Create a migration data set import in the target OUCCS environment
8. Run CMA batches in the target OUCCS environment
    - After running the CMA batches, there is a logic to check if the migration data set import status has completed successfully or not. **The deployment will fail if the migration data set import status is not in `APPLIED` state as part of the post deployment verification**
9.  Update the CM release version in the target OUCCS environment
    - There is a validation to check if the CM release version in the target OUCCS environment is aligned to the `Target Release` input parameter. **The deployment will fail if it is not aligned as part of the post deployment verification**
10. Perform post GIT checkout and cleanup
