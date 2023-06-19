type PowerTask =
  | 'poweroff'
  | 'reboot'
  | 'start'
  | 'startserver'
  | 'stop'
  | 'stopserver';

type PowerJobParams = Omit<JobParams, 'file' | 'line'>;

type BuildPowerJobParamsOptions = {
  isStopServers?: boolean;
  uuid?: string;
};

type BuildPowerJobParamsFunction = (
  options?: BuildPowerJobParamsOptions,
) => PowerJobParams;
