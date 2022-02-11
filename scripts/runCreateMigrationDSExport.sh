#!/bin/sh
#
# MODHISTORY: 05JAN2022: Janjan Orense: Initial Revision
# 
# This script will trigger the Inbound Web Service: CM-DevOpsRESTServices | Operation Name: createMigrationDataSetExport
# and will create the migration data set export data in the target environment.
# 
####################################################################################
# Required Input Parameters:
# 
# ENV_REST_APIS_URL         = The target environment REST API URL 
# ENV_SQL_REST_URL          = The target environment SQL REST URL
# ENV_USER_LOGIN            = The user login for the target environment
# ENV_OCI_STORAGE_NAMESPACE = The OCI storage namespace
# ENV_CMAEXPORTBUCKET       = The CMA export bucket in the OCI
# CMA_FILENAME              = The CMA export filename
# MIGR_REQ_ID               = The CMA migration request ID
# ENV_SRC_ENV_REFERENCE     = The CMA source environment reference
####################################################################################

ENV_REST_APIS_URL=$1
ENV_SQL_REST_URL=$2
ENV_USER_LOGIN=$3
ENV_OCI_STORAGE_NAMESPACE=$4
ENV_CMAEXPORTBUCKET=$5
CMA_FILENAME=$6
MIGR_REQ_ID=$7
ENV_SRC_ENV_REFERENCE=$8

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
	
	if [ -z "$ENV_CMAEXPORTBUCKET" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (CMA Export Bucket) is required. Exiting."
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

	if [ -z "$MIGR_REQ_ID" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (Migration Request ID) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi

	if [ -z "$ENV_SRC_ENV_REFERENCE" ]
	then
		echo "==================================================================================="
		echo "[ERROR] The Input Parameter (Source Environment Reference) is required. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
}

createMigrationDSExport()
{
	curl -X PUT "$ENV_REST_APIS_URL/cm/admin/devops/migrationDataSetExport/$CMA_FILENAME" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"request\":{\"migrationRequestId\":\"$MIGR_REQ_ID\",\"exportFileName\":\"$CMA_FILENAME\",\"srcEnvReference\":\"$ENV_SRC_ENV_REFERENCE\"}}" --user "$ENV_USER_LOGIN" >> tmp_create_data_set_export.json
}

getMigrationDSExportID()
{
	MIGR_DATA_SET_EXPORT_ID=`cat tmp_create_data_set_export.json | jq --raw-output '.response.exportDSId'`
	rm -f tmp_create_data_set_export.json
}

getMigrationDSExportStatus()
{
	curl -X POST --user "$ENV_USER_LOGIN" --data-binary "SELECT BO_STATUS_CD FROM F1_MIGR_DATA_ST WHERE MIGR_DATA_SET_ID='$MIGR_DATA_SET_EXPORT_ID' AND BUS_OBJ_CD='F1-MigrDataSetExport'" -H "Content-Type: application/sql" -k  $ENV_SQL_REST_URL >> tmp_f1_migr_data_st_status.json
	
	MIGR_DATA_SET_EXPORT_STATUS=`cat tmp_f1_migr_data_st_status.json | jq --raw-output '.items[].resultSet.items[].bo_status_cd' | sed 's/ *$//'`
	rm -f tmp_f1_migr_data_st_status.json
}

deleteCMAFileOS()
{
	echo "==================================================================================="
	echo "[INFO] Deleting the CMA file in the Object Storage: $CMA_FILENAME"
	echo "==================================================================================="
	oci os object delete -ns "$ENV_OCI_STORAGE_NAMESPACE" --bucket-name "$ENV_CMAEXPORTBUCKET" --name "$CMA_FILENAME" --force
}

validateCMAFileOS()
{
	echo "==================================================================================="
	echo "[INFO] Retrieving CMA Files in Object Storage: $ENV_CMAEXPORTBUCKET"
	echo "==================================================================================="
	oci os object list --bucket-name "$ENV_CMAEXPORTBUCKET" --fields name,timeCreated >> raw_get_cma_object_list.json
	OS_CMA_OBJECT_LIST_COUNT=`cat raw_get_cma_object_list.json | jq --raw-output '.data | length'`
	rm -f raw_get_cma_object_list.json

	if [ "$OS_CMA_OBJECT_LIST_COUNT" != '1' ]
	then
		echo "==================================================================================="
		echo "[ERROR] There should be only 1 CMA file in the object storage bucket. Exiting."
		echo "[ERROR] Please check the CMA Export Bucket: $ENV_CMAEXPORTBUCKET"
		echo "==================================================================================="
		exit 1
	else
		echo "==================================================================================="
		echo "[INFO] The CMA Export Process is Successful! Exiting."
		echo "==================================================================================="
	fi
}

# MAIN TASKS

validateInputParams
createMigrationDSExport
getMigrationDSExportID

# Check Migration Data Set Export Status
if [ "$MIGR_DATA_SET_EXPORT_ID" != "" ]
then

	getMigrationDSExportStatus
	
	if [ "$MIGR_DATA_SET_EXPORT_STATUS" != "" ]
	then
		
		while [ "$MIGR_DATA_SET_EXPORT_STATUS" != 'EXPORTED' ]
		do
		
			if [ "$MIGR_DATA_SET_EXPORT_STATUS" = 'ERROR' ]
			then
				echo "==================================================================================="
				echo "[ERROR] The CMA Export Process Failed. Exiting."
				echo "[ERROR] Please check Migration Data Set Export ID: $MIGR_DATA_SET_EXPORT_ID"
				echo "==================================================================================="

				deleteCMAFileOS
				exit 1
			fi
		
			echo "==================================================================================="
			echo "[INFO] Migration Data Set Export ID     : $MIGR_DATA_SET_EXPORT_ID"
			echo "[INFO] Migration Data Set Export Status : $MIGR_DATA_SET_EXPORT_STATUS"
			echo ""
			echo "[INFO] The data migration export batch is still running. Please be patient.."
			echo "==================================================================================="
			
			getMigrationDSExportStatus
			sleep 10
		done
		
		echo "==================================================================================="
		echo "[INFO] Migration Data Set Export ID     : $MIGR_DATA_SET_EXPORT_ID"
		echo "[INFO] Migration Data Set Export Status : $MIGR_DATA_SET_EXPORT_STATUS"
		echo ""
		echo "[INFO] The data migration export batch run is completed."
		echo "==================================================================================="

		validateCMAFileOS
		
	else
		echo "==================================================================================="
		echo "[ERROR] The Migration Data Set Export Status is null. Exiting."
		echo "==================================================================================="
		exit 1
	fi
	
else
	echo "==================================================================================="
	echo "[ERROR] The Migration Data Set Export ID is null. Exiting."
	echo "==================================================================================="
	exit 1
fi
