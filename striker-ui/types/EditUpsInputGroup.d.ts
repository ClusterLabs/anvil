type EditUpsInputGroupOptionalProps = {
  loading?: boolean;
};

type EditUpsInputGroupProps<M extends MapToInputTestID> =
  EditUpsInputGroupOptionalProps &
    Pick<AddUpsInputGroupProps<M>, 'formUtils' | 'previous' | 'upsTemplate'> & {
      upsUUID: string;
    };
