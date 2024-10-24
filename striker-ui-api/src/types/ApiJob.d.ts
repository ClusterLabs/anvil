/**
 * @prop started - EPOCH seconds that specify when the job started.
 */
type JobOverview = {
  host: {
    name: string;
    shortName: string;
    uuid: string;
  };
  modified: number;
  name: string;
  progress: number;
  started: number;
  title: string;
  uuid: string;
};

type JobOverviewList = Record<string, JobOverview>;

type JobData = {
  name: string;
  value: string;
};

type JobStatus = {
  value: string;
};

type JobDetail = JobOverview & {
  command: string;
  data: Record<string, JobData>;
  description: string;
  pid: number;
  status: Record<string, JobStatus>;
  updated: number;
};

type JobParamsDictionary = {
  uuid: string;
};

type JobRequestQuery = {
  command?: string;
  name?: string;
  start?: number;
};
