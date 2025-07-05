import MuiBox from '@mui/material/Box';
import MuiList from '@mui/material/List';
import MuiListItem from '@mui/material/ListItem';
import isEmpty from 'lodash/isEmpty';

import { REP_LABEL_PASSW } from '../lib/consts/REG_EXP_PATTERNS';

import disassembleCamel from '../lib/disassembleCamel';
import FlexBox from './FlexBox';
import { BodyText, MonoText, SensitiveText } from './Text';

const isNone = (value: unknown) =>
  value === undefined ||
  value === null ||
  (typeof value === 'number' && !Number.isFinite(value)) ||
  (typeof value === 'string' && value.trim().length === 0);

const renderEntryValueWithMono: RenderFormValueFunction = ({ entry }) => (
  <MonoText whiteSpace="nowrap">{String(entry)}</MonoText>
);

const renderEntryValueWithPassword: RenderFormValueFunction = (args) => {
  const { entry, key } = args;

  return REP_LABEL_PASSW.test(key) ? (
    <SensitiveText wrapper="mono">{String(entry)}</SensitiveText>
  ) : (
    renderEntryValueWithMono(args)
  );
};

const renderEntryValueBase: RenderFormValueFunction = (args) => {
  const { entry, hasPassword } = args;

  if (isNone(entry)) {
    return <BodyText>none</BodyText>;
  }

  return hasPassword
    ? renderEntryValueWithPassword(args)
    : renderEntryValueWithMono(args);
};

const renderEntryBase: RenderFormEntryFunction = (args) => {
  const { depth, entry, getLabel, hasPassword, key, nest, renderValue } = args;

  return (
    <FlexBox fullWidth growFirst row maxWidth="100%">
      <BodyText>
        {getLabel({ cap: disassembleCamel, depth, entry, hasPassword, key })}
      </BodyText>
      <MuiBox sx={{ maxWidth: '100%', overflowX: 'scroll' }}>
        {!nest &&
          renderValue(renderEntryValueBase, { depth, entry, hasPassword, key })}
      </MuiBox>
    </FlexBox>
  );
};

const skipBase: SkipFormEntryFunction = ({ key }) => /confirm|uuid/i.test(key);

const nestBase = <T,>(entry: T) =>
  entry !== null && typeof entry === 'object' && !isEmpty(entry);

const buildEntryList = <T extends FormEntries>({
  depth = 0,
  entries,
  getEntryLabel,
  getListProps,
  getListItemProps,
  hasPassword,
  listKey,
  maxDepth,
  renderEntry,
  renderEntryValue,
  skip,
}: {
  depth?: number;
  entries: T;
  getEntryLabel: GetFormEntryLabelFunction;
  getListProps?: GetFormEntriesPropsFunction<T>;
  getListItemProps?: GetFormEntryPropsFunction;
  listKey?: string;
} & Required<
  Pick<
    FormSummaryProps<T>,
    'hasPassword' | 'maxDepth' | 'renderEntry' | 'renderEntryValue' | 'skip'
  >
>): React.ReactElement => {
  const result: React.ReactElement[] = [];

  Object.entries(entries).forEach(([itemKey, entry]) => {
    const itemId = `form-summary-entry-${itemKey}`;

    const nest = nestBase(entry);

    const value = nest ? null : entry;

    const fnArgs: CommonFormEntryHandlerArgs = {
      depth,
      entry: value,
      hasPassword,
      key: itemKey,
    };

    if (!skip(skipBase, fnArgs)) {
      result.push(
        <MuiListItem
          key={itemId}
          sx={{ paddingLeft: `${depth}em` }}
          {...getListItemProps?.call(null, fnArgs)}
        >
          {renderEntry({
            depth,
            entry: value,
            getLabel: getEntryLabel,
            hasPassword,
            key: itemKey,
            nest,
            renderValue: renderEntryValue,
          })}
        </MuiListItem>,
      );
    }

    if (nest && depth < maxDepth) {
      result.push(
        buildEntryList<T>({
          depth: depth + 1,
          entries: entry as T,
          getEntryLabel,
          hasPassword,
          listKey: itemKey,
          maxDepth,
          renderEntry,
          renderEntryValue,
          skip,
        }),
      );
    }
  });

  const listId = `form-summary-list-${listKey ?? 'root'}`;

  return (
    <MuiList
      dense
      disablePadding
      key={listId}
      {...getListProps?.call(null, { depth, entries, key: listKey })}
    >
      {result}
    </MuiList>
  );
};

const FormSummary = <T extends FormEntries>({
  entries,
  getEntryLabel = ({ cap, key }) => cap(key),
  getListProps,
  getListItemProps,
  hasPassword = false,
  maxDepth = 3,
  renderEntry = renderEntryBase,
  renderEntryValue = (base, ...args) => base(...args),
  skip = (base, ...args) => base(...args),
}: FormSummaryProps<T>): ReturnType<React.FC<FormSummaryProps<T>>> =>
  buildEntryList<T>({
    entries,
    getEntryLabel,
    getListProps,
    getListItemProps,
    hasPassword,
    maxDepth,
    renderEntry,
    renderEntryValue,
    skip,
  });

export default FormSummary;
