import { FC, ReactElement, useMemo, useState } from 'react';

import CommonUpsInputGroup from './CommonUpsInputGroup';
import FlexBox from '../FlexBox';
import SelectWithLabel from '../SelectWithLabel';
import Spinner from '../Spinner';
import { BodyText } from '../Text';

const INPUT_ID_UPS_TYPE_ID = 'add-ups-select-ups-type-id';

const AddUpsInputGroup: FC<AddUpsInputGroupProps> = ({
  loading: isExternalLoading,
  previous = {},
  upsTemplate,
}) => {
  const { upsTypeId: previousUpsTypeId = '' } = previous;

  const [inputUpsTypeIdValue, setInputUpsTypeIdValue] =
    useState<string>(previousUpsTypeId);

  const upsTypeOptions = useMemo<SelectItem[]>(
    () =>
      upsTemplate
        ? Object.entries(upsTemplate).map<SelectItem>(
            ([upsTypeId, { brand, description }]) => ({
              displayValue: (
                <FlexBox spacing={0}>
                  <BodyText inverted>{brand}</BodyText>
                  <BodyText inverted>{description}</BodyText>
                </FlexBox>
              ),
              value: upsTypeId,
            }),
          )
        : [],
    [upsTemplate],
  );

  const pickUpsTypeElement = useMemo(
    () =>
      upsTemplate && (
        <SelectWithLabel
          formControlProps={{ sx: { marginTop: '.3em' } }}
          id={INPUT_ID_UPS_TYPE_ID}
          label="UPS type"
          onChange={({ target: { value: rawNewValue } }) => {
            const newValue = String(rawNewValue);

            setInputUpsTypeIdValue(newValue);
          }}
          selectItems={upsTypeOptions}
          selectProps={{
            onClearIndicatorClick: () => {
              setInputUpsTypeIdValue('');
            },
            renderValue: (rawValue) => {
              const upsTypeId = String(rawValue);
              const { brand } = upsTemplate[upsTypeId];

              return brand;
            },
          }}
          value={inputUpsTypeIdValue}
        />
      ),
    [inputUpsTypeIdValue, upsTypeOptions, upsTemplate],
  );
  const content = useMemo<ReactElement>(
    () =>
      isExternalLoading ? (
        <Spinner />
      ) : (
        <FlexBox>
          {pickUpsTypeElement}
          {inputUpsTypeIdValue && <CommonUpsInputGroup previous={previous} />}
        </FlexBox>
      ),
    [inputUpsTypeIdValue, isExternalLoading, pickUpsTypeElement, previous],
  );

  return content;
};

export { INPUT_ID_UPS_TYPE_ID };

export default AddUpsInputGroup;
