import { Box, List as MUIList, ListItem as MUIListItem } from '@mui/material';
import { FC, ReactElement } from 'react';

import { REP_LABEL_PASSW } from '../lib/consts/REG_EXP_PATTERNS';

import disassembleCamel from '../lib/disassembleCamel';
import FlexBox from './FlexBox';
import { BodyText, MonoText, SensitiveText } from './Text';

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

  if (
    ['', null, undefined].some((bad) => entry === bad) ||
    Number.isNaN(entry)
  ) {
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
      <Box sx={{ maxWidth: '100%', overflowX: 'scroll' }}>
        {!nest &&
          renderValue(renderEntryValueBase, { depth, entry, hasPassword, key })}
      </Box>
    </FlexBox>
  );
};

const skipBase: SkipFormEntryFunction = ({ key }) => !/confirm|uuid/i.test(key);

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
  entries: FormEntries;
  getEntryLabel: GetFormEntryLabelFunction;
  getListProps?: GetFormEntriesPropsFunction;
  getListItemProps?: GetFormEntryPropsFunction;
  listKey?: string;
} & Required<
  Pick<
    FormSummaryProps<T>,
    'hasPassword' | 'maxDepth' | 'renderEntry' | 'renderEntryValue' | 'skip'
  >
>): ReactElement => {
  const result: ReactElement[] = [];

  Object.entries(entries).forEach(([itemKey, entry]) => {
    const itemId = `form-summary-entry-${itemKey}`;

    const nest = entry !== null && typeof entry === 'object';

    const value = nest ? null : entry;

    const fnArgs: CommonFormEntryHandlerArgs = {
      depth,
      entry: value,
      hasPassword,
      key: itemKey,
    };

    if (skip(skipBase, fnArgs)) {
      result.push(
        <MUIListItem
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
        </MUIListItem>,
      );
    }

    if (nest && depth < maxDepth) {
      result.push(
        buildEntryList<T>({
          depth: depth + 1,
          entries: entry,
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
    <MUIList
      dense
      disablePadding
      key={listId}
      {...getListProps?.call(null, { depth, entries, key: listKey })}
    >
      {result}
    </MUIList>
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
}: FormSummaryProps<T>): ReturnType<FC<FormSummaryProps<T>>> =>
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
