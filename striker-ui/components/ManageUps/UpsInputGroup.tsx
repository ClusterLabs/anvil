import MuiGrid from '@mui/material/Grid2';
import styled from '@mui/material/styles/styled';
import { useMemo } from 'react';

import { BLACK } from '../../lib/consts/DEFAULT_THEME';

import FlexBox from '../FlexBox';
import Link from '../Link';
import MessageBox from '../MessageBox';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import SelectWithLabel from '../SelectWithLabel';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import UncontrolledInput from '../UncontrolledInput';
import { UpsFormContext, useUpsFormContext } from './UpsForm';

import {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_ID_UPS_TYPE,
} from './inputIds';

type UpsInputGroupProps = {
  loading?: boolean;
  upsTemplate: APIUpsTemplate;
};

const InvertedLink = styled(Link)({
  color: BLACK,
  display: 'inline-flex',
  textDecorationColor: BLACK,
});

const UpsInputGroup = (
  ...[props]: Parameters<React.FC<UpsInputGroupProps>>
): ReturnType<React.FC<UpsInputGroupProps>> => {
  const { loading, upsTemplate } = props;

  const context = useUpsFormContext(UpsFormContext);

  const upsTypeOptions = useMemo<SelectItem[]>(
    () =>
      Object.entries(upsTemplate).map<SelectItem>(
        ([
          upsTypeId,
          {
            brand,
            description,
            links: { 0: link },
          },
        ]) => {
          let linkElement: React.ReactNode;

          if (link) {
            const { linkHref, linkLabel } = link;

            linkElement = (
              <InvertedLink
                href={linkHref}
                onClick={(event) => {
                  // Don't trigger the (parent) item selection event.
                  event.stopPropagation();
                }}
                target="_blank"
              >
                {linkLabel}
              </InvertedLink>
            );
          }

          return {
            displayValue: (
              <FlexBox spacing={0}>
                <BodyText inverted>{brand}</BodyText>
                <BodyText inverted>
                  {description} ({linkElement})
                </BodyText>
              </FlexBox>
            ),
            value: upsTypeId,
          };
        },
      ),
    [upsTemplate],
  );

  if (!context) {
    return <MessageBox type="error">Missing form context.</MessageBox>;
  }

  const { changeFieldValue, formik, handleChange } = context.formikUtils;

  if (loading) {
    return <Spinner />;
  }

  return (
    <MuiGrid
      columns={{
        xs: 1,
        sm: 2,
      }}
      container
      spacing="1em"
      width="100%"
    >
      <MuiGrid width="100%">
        <SelectWithLabel
          id={INPUT_ID_UPS_TYPE}
          label="UPS type"
          name={INPUT_ID_UPS_TYPE}
          onChange={(event) => {
            const { value } = event.target;

            changeFieldValue(INPUT_ID_UPS_TYPE, value, true);
          }}
          required
          selectItems={upsTypeOptions}
          selectProps={{
            onClearIndicatorClick: () => {
              changeFieldValue(INPUT_ID_UPS_TYPE, '', true);
            },
            renderValue: (value) => {
              const typeId = String(value);

              const { brand } = upsTemplate[typeId];

              return brand;
            },
          }}
          value={formik.values[INPUT_ID_UPS_TYPE]}
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={INPUT_ID_UPS_NAME}
              label="Host name"
              name={INPUT_ID_UPS_NAME}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_UPS_NAME]}
            />
          }
        />
      </MuiGrid>
      <MuiGrid size={1}>
        <UncontrolledInput
          input={
            <OutlinedInputWithLabel
              id={INPUT_ID_UPS_IP}
              label="IP address"
              name={INPUT_ID_UPS_IP}
              onChange={handleChange}
              required
              value={formik.values[INPUT_ID_UPS_IP]}
            />
          }
        />
      </MuiGrid>
    </MuiGrid>
  );
};

export type { UpsInputGroupProps };

export default UpsInputGroup;
