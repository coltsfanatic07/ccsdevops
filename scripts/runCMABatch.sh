#!/bin/sh
#
# MODHISTORY: 13DEC2021: Janjan Orense: Initial Revision
# 
# Use this script to run any CMA batches (F1-MGDIM, F1-MGDPR, F1-MGOPR, F1-MGTPR, F1-MGOAP, F1-MGTAP)
# 
# This script will trigger the Inbound Web Service: F1-SubmitJob and will submit the job with the 
# default batch parameters (maintenanceObject) only. 
# 
####################################################################################
# Required Input Parameters:
# 
# ENV_REST_APIS_URL = The target environment REST API URL 
# ENV_SQL_REST_URL  = The target environment SQL REST URL
# ENV_USER_LOGIN    = The user login for the target environment
# BATCH_CD          = The CMA batch to run in the target environment
####################################################################################

ENV_REST_APIS_URL=$1
ENV_SQL_REST_URL=$2
ENV_USER_LOGIN=$3
BATCH_CD=$4
BATCH_PROCESS_DT=`date +%Y-%m-%d`

validateInputParams()
{
	if [ -z "$ENV_REST_APIS_URL" ]
	then
		echo "[ERROR] The Input Parameter (Environment REST API URL) is required. Exiting."
		exit 1
	fi
	
	if [ -z "$ENV_SQL_REST_URL" ]
	then
		echo "[ERROR] The Input Parameter (Environment SQL REST URL) is required. Exiting."
		exit 1
	fi
	
	if [ -z "$ENV_USER_LOGIN" ]
	then
		echo "[ERROR] The Input Parameter (Environment User Login) is required. Exiting."
		exit 1
	fi
	
	if [ -z "$BATCH_CD" ]
	then
		echo "[ERROR] The Input Parameter (Batch Code) is required. Exiting."
		exit 1
	fi
		
	if [ "$BATCH_CD" = 'F1-MGDIM' ]
	then
		echo "==================================================================================="
		echo "[INFO] Validation Successful - Proceeding.."
		echo "==================================================================================="
	elif [ "$BATCH_CD" = 'F1-MGDPR' ]
	then
		echo "==================================================================================="
		echo "[INFO] Validation Successful - Proceeding.."
		echo "==================================================================================="
	elif [ "$BATCH_CD" = 'F1-MGOPR' ]
	then
		echo "==================================================================================="
		echo "[INFO] Validation Successful - Proceeding.."
		echo "==================================================================================="
	elif [ "$BATCH_CD" = 'F1-MGTPR' ]
	then
		echo "==================================================================================="
		echo "[INFO] Validation Successful - Proceeding.."
		echo "==================================================================================="
	elif [ "$BATCH_CD" = 'F1-MGOAP' ]
	then
		echo "==================================================================================="
		echo "[INFO] Validation Successful - Proceeding.."
		echo "==================================================================================="
	elif [ "$BATCH_CD" = 'F1-MGTAP' ]
	then
		echo "==================================================================================="
		echo "[INFO] Validation Successful - Proceeding.."
		echo "==================================================================================="
	else
		echo "[ERROR] This script is exclusive for CMA batches only. Exiting."
		exit 1
	fi
	
}

defBatchParams()
{
	# Batch: Migration Data Set Import Monitor
	if [ "$BATCH_CD" = 'F1-MGDIM' ]
	then
		BATCH_PARAM_MO_VAL="F1-MIGRDS"
	fi

	# Batch: Migration Data Set Export Monitor
	if [ "$BATCH_CD" = 'F1-MGDPR' ]
	then
		BATCH_PARAM_MO_VAL="F1-MIGRDS"
	fi

	# Batch: Migration Object Monitor
	if [ "$BATCH_CD" = 'F1-MGOPR' ]
	then
		BATCH_PARAM_MO_VAL="F1-MIGROBJ"
	fi

	# Batch: Migration Transaction Monitor
	if [ "$BATCH_CD" = 'F1-MGTPR' ]
	then
		BATCH_PARAM_MO_VAL="F1-MIGRTX"
	fi

	# Batch: Migration Object Monitor - Apply
	# No Batch Parameter is Required for 'F1-MGOAP'
	
	# Batch: Migration Transaction Monitor - Apply
	# No Batch Parameter is Required for 'F1-MGTAP'
}

submitBatch()
{
	curl -X POST "$ENV_REST_APIS_URL/common/batch/batchJobSubmission/" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"F1SubmitJob\":{\"jobDetails\":{\"batchJobId\":\"\",\"batchControl\":\"$BATCH_CD\",\"batchNumber\":0,\"batchRerunNumber\":0,\"submissionMethod\":\"F1GE\",\"user\":\"\",\"emailAddress\":\"\",\"language\":\"ENG\",\"batchStartDateTime\":\"\",\"threadCount\":0,\"batchThreadNumber\":0,\"processDate\":\"$BATCH_PROCESS_DT\",\"maximumCommitRecords\":0,\"maximumTimeoutMinutes\":0,\"isTracingProgramStart\":false,\"isTracingProgramEnd\":false,\"isTracingSQL\":false,\"isTracingStandardOut\":false,\"batchJobExtraParameter\":[{\"batchJobId\":\"\",\"sequence\":10,\"batchParameterName\":\"maintenanceObject\",\"batchParameterValue\":\"$BATCH_PARAM_MO_VAL\"}]}}}" --user "$ENV_USER_LOGIN"  >> tmp_submitBatch.json
}

submitBatchForF1MGTPR()
{
	curl -X POST "$ENV_REST_APIS_URL/common/batch/batchJobSubmission/" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"F1SubmitJob\":{\"jobDetails\":{\"batchJobId\":\"\",\"batchControl\":\"$BATCH_CD\",\"batchNumber\":0,\"batchRerunNumber\":0,\"submissionMethod\":\"F1GE\",\"user\":\"\",\"emailAddress\":\"\",\"language\":\"ENG\",\"batchStartDateTime\":\"\",\"threadCount\":0,\"batchThreadNumber\":0,\"processDate\":\"$BATCH_PROCESS_DT\",\"maximumCommitRecords\":0,\"maximumTimeoutMinutes\":0,\"isTracingProgramStart\":false,\"isTracingProgramEnd\":false,\"isTracingSQL\":false,\"isTracingStandardOut\":false,\"batchJobExtraParameter\":[{\"batchJobId\":\"\",\"sequence\":10,\"batchParameterName\":\"maintenanceObject\",\"batchParameterValue\":\"$BATCH_PARAM_MO_VAL\"},{\"sequence\":20,\"batchParameterName\":\"isRestrictedByBatchCode\",\"batchParameterValue\":\"true\"}]}}}" --user "$ENV_USER_LOGIN" >> tmp_submitBatch.json
}

submitBatchForF1MGOAP()
{
	curl -X POST "$ENV_REST_APIS_URL/common/batch/batchJobSubmission/" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"F1SubmitJob\":{\"jobDetails\":{\"batchJobId\":\"\",\"batchControl\":\"$BATCH_CD\",\"batchNumber\":0,\"batchRerunNumber\":0,\"submissionMethod\":\"F1GE\",\"user\":\"\",\"emailAddress\":\"\",\"language\":\"ENG\",\"batchStartDateTime\":\"\",\"threadCount\":0,\"batchThreadNumber\":0,\"processDate\":\"$BATCH_PROCESS_DT\",\"maximumCommitRecords\":0,\"maximumTimeoutMinutes\":0,\"isTracingProgramStart\":false,\"isTracingProgramEnd\":false,\"isTracingSQL\":false,\"isTracingStandardOut\":false}}}" --user "$ENV_USER_LOGIN" >> tmp_submitBatch.json
}

getBatchJobID()
{
	BATCH_JOB_ID=`cat tmp_submitBatch.json | jq --raw-output '.jobDetails.batchJobId'`
	rm -f tmp_submitBatch.json
}

getBatchJobStatFlag()
{
	curl -X POST --user "$ENV_USER_LOGIN" --data-binary "SELECT BATCH_JOB_STAT_FLG FROM CI_BATCH_JOB WHERE BATCH_JOB_ID='"$BATCH_JOB_ID"';" -H "Content-Type: application/sql" -k $ENV_SQL_REST_URL >> tmp_BatchJobStatFlg.json
	
	BATCH_JOB_STAT_FLG=`cat tmp_BatchJobStatFlg.json | jq --raw-output '.items[].resultSet.items[].batch_job_stat_flg'`
	rm -f tmp_BatchJobStatFlg.json
}


# MAIN TASKS

validateInputParams
defBatchParams

# Submit Batch & Retrieve Batch Job ID
if [ "$BATCH_CD" = 'F1-MGTPR' ]
then
	submitBatchForF1MGTPR
	getBatchJobID
elif [ "$BATCH_CD" = 'F1-MGOAP' ]
then
	submitBatchForF1MGOAP
	getBatchJobID
else
	submitBatch
	getBatchJobID
fi

# Check Batch Job Execution
if [ "$BATCH_JOB_ID" != "" ]
then

	getBatchJobStatFlag
	
	if [ "$BATCH_JOB_STAT_FLG" != "" ]
	then
		while [ "$BATCH_JOB_STAT_FLG" != 'ED' ]
		do
			echo "==================================================================================="
			echo "[INFO] Batch Job             : $BATCH_CD"
			echo "[INFO] Batch Job ID          : $BATCH_JOB_ID"
			echo "[INFO] Batch Job Status Flag : $BATCH_JOB_STAT_FLG"
			echo ""
			echo "[INFO] The batch is still running. Please be patient.."
			echo "==================================================================================="
			
			getBatchJobStatFlag
			sleep 10
		done
		
		echo "==================================================================================="
		echo "[INFO] Batch Job             : $BATCH_CD"
		echo "[INFO] Batch Job ID          : $BATCH_JOB_ID"
		echo "[INFO] Batch Job Status Flag : $BATCH_JOB_STAT_FLG"
		echo ""
		echo "[INFO] The batch run is completed. Exiting."
		echo "==================================================================================="
		
	else
		echo "[ERROR] The Batch Job Status Flag is null. Exiting."
		exit 1
	fi
	
else
	echo "[ERROR] The Batch Job ID is null. Exiting."
	exit 1
fi
