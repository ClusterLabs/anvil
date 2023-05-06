type PowerTask = 'poweroff' | 'reboot' | 'start' | 'stop';

type PowerJobParams = Omit<
  JobParams,
  'file' | 'line' | 'job_data' | 'job_progress'
>;

type BuildPowerJobParamsOptions = {
  isStopServers?: boolean;
  uuid?: string;
};

type BuildPowerJobParamsFunction = (
  options?: BuildPowerJobParamsOptions,
) => PowerJobParams;
