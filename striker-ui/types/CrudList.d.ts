type CrudListFormTools = {
  confirm: {
    finish: (header: React.ReactNode, message: Message) => void;
    loading: (value: boolean) => void;
    open: (value: boolean) => void;
    prepare: (value: React.SetStateAction<ConfirmDialogProps>) => void;
  };
};

type CrudListItemClickHandler = Exclude<
  ListProps<Overview>['onItemClick'],
  undefined
>;

type CrudListOptionalProps<Overview> = {
  getAddLoading?: (previous?: boolean) => boolean;
  getEditLoading?: (previous?: boolean) => boolean;
  listProps?: Partial<ListProps<Overview>>;
  onItemClick?: (
    base: CrudListItemClickHandler,
    ...args: Parameters<CrudListItemClickHandler>
  ) => ReturnType<CrudListItemClickHandler>;
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
