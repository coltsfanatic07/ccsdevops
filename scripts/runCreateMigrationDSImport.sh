#!/bin/sh
#
# MODHISTORY: 15DEC2021: Janjan Orense: Initial Revision
# 
# This script will trigger the Inbound Web Service: CM-DevOpsRESTServices | Operation Name: addMigrationDataSetImport
# and will create the migration data set import data in the target environment.
# 
# This script will validate if the migration data set import data is created successfully and will check the status
# if it has reached the 'Ready to Compare' (READY2COMP) status. If the migration data set import is on 'Error'
# status, the script will terminate and will exit with error.
# 
####################################################################################
# Required Input Parameters:
# 
# ENV_REST_APIS_URL         = The target environment REST API URL 
# ENV_SQL_REST_URL          = The target environment SQL REST URL
# ENV_USER_LOGIN            = The user login for the target environment
# ENV_OCI_STORAGE_NAMESPACE = The OCI storage namespace
# ENV_CMAIMPORTBUCKET       = The CMA import bucket in the OCI
# CMA_FILENAME              = The CMA import filename
####################################################################################

ENV_REST_APIS_URL=$1
ENV_SQL_REST_URL=$2
ENV_USER_LOGIN=$3
ENV_OCI_STORAGE_NAMESPACE=$4
ENV_CMAIMPORTBUCKET=$5
CMA_FILENAME=$6

validateInputParams()
{
	if [ -z "$ENV_REST_APIS_URL" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (Environment REST API URL) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
	if [ -z "$ENV_SQL_REST_URL" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (Environment SQL REST URL) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
	if [ -z "$ENV_USER_LOGIN" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (Environment User Login) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
	if [ -z "$ENV_OCI_STORAGE_NAMESPACE" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (OCI Storage Namespace) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
	if [ -z "$ENV_CMAIMPORTBUCKET" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (CMA Import Bucket) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
	if [ -z "$CMA_FILENAME" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (CMA Filename) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
}

createMigrationDSImport()
{
	curl -X PUT "$ENV_REST_APIS_URL/cm/admin/devops/migrationDataSetImport/$CMA_FILENAME" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"input\":{\"exportFileName\":\"$CMA_FILENAME\",\"autoApply\":\"F1YS\"}}" --user "$ENV_USER_LOGIN" >> tmp_create_migration_data_set_import.json
}

getMigrationDSImportID()
{
	MIGR_DATA_SET_IMPORT_ID=`cat tmp_create_migration_data_set_import.json | jq --raw-output '.output.importDSId'`
	rm -f tmp_create_migration_data_set_import.json
}

getMigrationDSImportStatus()
{
	curl -X POST --user "$ENV_USER_LOGIN" --data-binary "SELECT BO_STATUS_CD FROM F1_MIGR_DATA_ST WHERE MIGR_DATA_SET_ID='$MIGR_DATA_SET_IMPORT_ID' AND BUS_OBJ_CD='F1-MigrDataSetImport'" -H "Content-Type: application/sql" -k  $ENV_SQL_REST_URL >> tmp_f1_migr_data_st_status.json
	
	MIGR_DATA_SET_IMPORT_STATUS=`cat tmp_f1_migr_data_st_status.json | jq --raw-output '.items[].resultSet.items[].bo_status_cd' | sed 's/ *$//'`
	rm -f tmp_f1_migr_data_st_status.json
}

deleteCMAFileOS()
{
	echo "==================================================================================="
	echo "[INFO] Deleting the CMA file in the Object Storage: $CMA_FILENAME"
	echo "==================================================================================="
	oci os object delete -ns "$ENV_OCI_STORAGE_NAMESPACE" --bucket-name "$ENV_CMAIMPORTBUCKET" --name "$CMA_FILENAME" --force
}


# MAIN TASKS

validateInputParams
createMigrationDSImport
getMigrationDSImportID

# Check Migration Data Set Import Status
if [ "$MIGR_DATA_SET_IMPORT_ID" != "" ]
then

	getMigrationDSImportStatus
	
	if [ "$MIGR_DATA_SET_IMPORT_STATUS" != "" ]
	then
		
		while [ "$MIGR_DATA_SET_IMPORT_STATUS" != 'READY2COMP' ]
		do
		
			if [ "$MIGR_DATA_SET_IMPORT_STATUS" = 'ERROR' ]
			then
				echo "==================================================================================="
				echo "[ERROR] The CMA Import Process Failed. Exiting."
				echo "[ERROR] Please check Migration Data Set Import ID: $MIGR_DATA_SET_IMPORT_ID"
				echo "==================================================================================="

				deleteCMAFileOS
				exit 1
			fi
		
			echo "==================================================================================="
			echo "[INFO] Migration Data Set Import ID     : $MIGR_DATA_SET_IMPORT_ID"
			echo "[INFO] Migration Data Set Import Status : $MIGR_DATA_SET_IMPORT_STATUS"
			echo ""
			echo "[INFO] The data migration import batch is still running. Please be patient.."
			echo "==================================================================================="
			
			getMigrationDSImportStatus
			sleep 10
		done
		
		echo "==================================================================================="
		echo "[INFO] Migration Data Set Import ID     : $MIGR_DATA_SET_IMPORT_ID"
		echo "[INFO] Migration Data Set Import Status : $MIGR_DATA_SET_IMPORT_STATUS"
		echo ""
		echo "[INFO] The data migration import batch run is completed."
		echo "==================================================================================="
		
		deleteCMAFileOS
		
		# pass the following environment variables to the pipeline
		touch .env
		echo "MIGR_DATA_SET_IMPORT_ID=$MIGR_DATA_SET_IMPORT_ID" >> .env
		echo "MIGR_DATA_SET_IMPORT_STATUS=$MIGR_DATA_SET_IMPORT_STATUS" >> .env
		
		echo "==================================================================================="
		echo "[INFO] The CMA Import Process is Successful! Exiting."
		echo "==================================================================================="
        
	else
		echo "==================================================================================="
		echo "[ERROR] The Migration Data Set Import Status is null. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
else
	echo "==================================================================================="
	echo "[ERROR] The Migration Data Set Import ID is null. Exiting."
	echo "==================================================================================="
	exit 1
fi
