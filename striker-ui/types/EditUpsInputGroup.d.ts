type EditUpsInputGroupOptionalProps = {
  loading?: boolean;
};

type EditUpsInputGroupProps = EditUpsInputGroupOptionalProps &
  Pick<AddUpsInputGroupProps, 'previous' | 'upsTemplate'> & {
    upsUUID: string;
  };
