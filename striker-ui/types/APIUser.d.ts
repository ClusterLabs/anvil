type APIUserOverview = {
  userName: string;
  userUUID: string;
};

type APIUserOverviewList = Record<string, APIUserOverview>;

type CreateOrUpdateUserRequestBody = {
  userName: string;
  password: string;
};
