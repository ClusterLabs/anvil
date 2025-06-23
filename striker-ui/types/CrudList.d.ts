type CrudListEntryRef<Detail> = {
  set: (value: Detail) => void;
  value?: Detail;
};

type CrudListConfirmHelpers = {
  finish: (header: React.ReactNode, message: Message) => void;
  loading: (value: boolean) => void;
  open: (value?: boolean) => void;
  prepare: (value: ConfirmDialogProps) => void;
};

type CrudListFormTools = {
  add: {
    open: (value?: boolean) => void;
  };
  confirm: CrudListConfirmHelpers;
  edit: {
    open: (value?: boolean) => void;
  };
};

type CrudListItemClickHandler<Overview> = Exclude<
  ListProps<Overview>['onItemClick'],
  undefined
>;

type DeletePromiseChainGetter<T> = (
  checks: ArrayChecklist,
  urlPrefix: string,
) => Promise<T>[];

type CrudListOptionalProps<Overview, Detail> = {
  entryUrlPrefix?: string;
  formDialogProps?: Partial<
    Record<'add' | 'common' | 'edit', Partial<DialogWithHeaderProps>>
  >;
  getAddLoading?: (previous?: boolean) => boolean;
  getDeletePromiseChain?: <T>(
    base: DeletePromiseChainGetter<T>,
    ...args: Parameters<DeletePromiseChainGetter<T>>
  ) => ReturnType<DeletePromiseChainGetter<T>>;
  getEditLoading?: (previous?: boolean) => boolean;
  listProps?: Partial<ListProps<Overview>>;
  onItemClick?: (
    base: CrudListItemClickHandler<Overview>,
    misc: {
      args: Parameters<CrudListItemClickHandler<Overview>>;
      entry: CrudListEntryRef<Detail>;
      tools: CrudListFormTools;
    },
  ) => ReturnType<CrudListItemClickHandler<Overview>>;
  onValidateEntriesChange?: (value: boolean) => void;
  refreshInterval?: number;
};

type CrudListProps<
  Overview,
  Detail,
  OverviewList extends Record<string, Overview> = Record<string, Overview>,
> = Pick<ListProps<Overview>, 'listEmpty' | 'renderListItem'> &
  CrudListOptionalProps<Overview, Detail> & {
    addHeader: React.ReactNode | (() => React.ReactNode);
    editHeader:
      | React.ReactNode
      | ((detail: Detail | undefined) => React.ReactNode);
    entriesUrl: string;
    getDeleteErrorMessage: (previous: Message) => Message;
    getDeleteHeader: BuildDeleteDialogPropsArgs['getConfirmDialogTitle'];
    getDeleteSuccessMessage: () => Message;
    renderAddForm: (
      tools: CrudListFormTools,
      list: OverviewList | undefined,
    ) => React.ReactNode;
    renderDeleteItem: (
      entries: OverviewList | undefined,
      ...args: Parameters<RenderFormEntryFunction>
    ) => ReturnType<RenderFormEntryFunction>;
    renderEditForm: (
      tools: CrudListFormTools,
      detail: Detail | undefined,
      list: OverviewList | undefined,
    ) => React.ReactNode;
  };
