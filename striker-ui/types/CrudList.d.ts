type CrudListFormTools = {
  confirm: {
    finish: (header: React.ReactNode, message: Message) => void;
    loading: (value: boolean) => void;
    open: (value?: boolean) => void;
    prepare: (value: React.SetStateAction<ConfirmDialogProps>) => void;
  };
  add: {
    open: (value?: boolean) => void;
  };
  edit: {
    open: (value?: boolean) => void;
  };
};

type CrudListItemClickHandler = Exclude<
  ListProps<Overview>['onItemClick'],
  undefined
>;

type DeletePromiseChainGetter<T> = (
  checks: ArrayChecklist,
  urlPrefix: string,
) => Promise<T>[];

type CrudListOptionalProps<Overview> = {
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
    base: CrudListItemClickHandler,
    ...args: Parameters<CrudListItemClickHandler>
  ) => ReturnType<CrudListItemClickHandler>;
  onValidateEntriesChange?: (value: boolean) => void;
  refreshInterval?: number;
};

type CrudListProps<
  Overview,
  Detail,
  OverviewList extends Record<string, Overview> = Record<string, Overview>,
> = Pick<ListProps<Overview>, 'listEmpty' | 'renderListItem'> &
  CrudListOptionalProps<Overview> & {
    addHeader: React.ReactNode | (() => React.ReactNode);
    editHeader:
      | React.ReactNode
      | ((detail: Detail | undefined) => React.ReactNode);
    entriesUrl: string;
    getDeleteErrorMessage: (previous: Message) => Message;
    getDeleteHeader: BuildDeleteDialogPropsArgs['getConfirmDialogTitle'];
    getDeleteSuccessMessage: () => Message;
    renderAddForm: (tools: CrudListFormTools) => React.ReactNode;
    renderDeleteItem: (
      entries: OverviewList | undefined,
      ...args: Parameters<RenderFormEntryFunction>
    ) => ReturnType<RenderFormEntryFunction>;
    renderEditForm: (
      tools: CrudListFormTools,
      detail: Detail | undefined,
    ) => React.ReactNode;
  };
