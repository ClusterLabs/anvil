type JobParams = InsertOrUpdateFunctionCommonParams & {
  job_command: string;
  job_data?: string;
  job_name: string;
  job_title: string;
  job_description: string;
  job_host_uuid?: string;
  job_progress?: number;
};
