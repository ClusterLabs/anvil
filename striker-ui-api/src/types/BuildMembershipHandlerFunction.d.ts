type MembershipTask = 'join' | 'leave';

type MembershipJobParams = Omit<JobParams, 'file' | 'line'>;

type BuildMembershipJobParamsOptions = {
  isActiveMember?: boolean;
};

type BuildMembershipJobParamsFunction = (
  uuid: string,
  options?: BuildMembershipJobParamsOptions,
) => Promise<MembershipJobParams | undefined>;
