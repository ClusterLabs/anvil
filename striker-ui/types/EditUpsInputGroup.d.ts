type EditUpsInputGroupOptionalProps = {
  loading?: boolean;
};

type EditUpsInputGroupProps = EditUpsInputGroupOptionalProps &
  Pick<CommonUpsInputGroupProps, 'previous'> & { upsUUID: string };
