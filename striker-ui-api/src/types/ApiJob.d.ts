/**
 * @prop started - EPOCH seconds that specify when the job started.
 */
type JobOverview = {
  host: {
    name: string;
    shortName: string;
    uuid: string;
  };
  name: string;
  progress: number;
  started: number;
  title: string;
  uuid: string;
};

type JobOverviewList = Record<string, JobOverview>;

type JobDetail = JobOverview & {
  command: string;
  description: string;
};

type JobRequestQuery = {
  command?: string;
  start?: number;
};
