type PowerTask =
  | 'poweroff'
  | 'reboot'
  | 'start'
  | 'startserver'
  | 'stop'
  | 'stopserver';

type PowerJobParams = Omit<JobParams, 'file' | 'line'>;

type BuildPowerJobParamsOptions = {
  force?: boolean;
  isStopServers?: boolean;
  runOn?: string;
  uuid?: string;
};

type BuildPowerJobParamsFunction = (
  options?: BuildPowerJobParamsOptions,
) => PowerJobParams;
