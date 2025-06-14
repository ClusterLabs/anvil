import * as yup from 'yup';

const buildNameSchema = (skip: null | string, fences: APIFenceOverviewList) => {
  let values: APIFenceOverview[] = Object.values(fences);

  if (skip) {
    values = values.filter((fence) => fence.fenceUUID !== skip);
  }

  const names = values.map<string>((fence) => fence.fenceName);

  return yup.string().min(1).max(32).notOneOf(names, '${path} already exists');
};

export default buildNameSchema;
