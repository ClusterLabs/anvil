/**
 * @prop started - EPOCH seconds that specify when the job started.
 */
type APIJobOverview = {
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

type APIJobOverviewList = Record<string, APIJobOverview>;
