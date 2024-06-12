/**
 * @prop started - EPOCH seconds that specify when the job started.
 */
type JobOverview = {
  command: string;
  description: string;
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

type JobRequestQuery = {
  command?: string;
  start?: number;
};
