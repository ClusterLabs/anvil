import { Album as AlbumIcon, Expand as ExpandIcon } from '@mui/icons-material';
import { Grid } from '@mui/material';
import { capitalize } from 'lodash';
import { FC, useMemo, useRef, useState } from 'react';

import { DialogWithHeader } from '../Dialog';
import FlexBox from '../FlexBox';
import IconButton from '../IconButton';
import List from '../List';
import ServerAddDiskForm from './ServerAddDiskForm';
import ServerChangeIsoForm from './ServerChangeIsoForm';
import { BodyText, MonoText } from '../Text';

const ServerDiskList: FC<ServerDiskListProps> = (props) => {
  const { detail } = props;

  const addDiskDialogRef = useRef<DialogForwardedRefContent>(null);
  const growDiskDialogRef = useRef<DialogForwardedRefContent>(null);

  const changeIsoDialogRef = useRef<DialogForwardedRefContent>(null);

  const [target, setTarget] = useState<string | undefined>();

  const disks = useMemo(
    () =>
      detail.devices.disks.reduce<Record<string, APIServerDetailDisk>>(
        (previous, disk) => {
          previous[disk.target.dev] = disk;

          return previous;
        },
        {},
      ),
    [detail.devices.disks],
  );

  return (
    <>
      <List
        allowAddItem
        header
        listEmpty="No disk(s) found."
        listItems={disks}
        onAdd={() => {
          setTarget(undefined);

          addDiskDialogRef.current?.setOpen(true);
        }}
        renderListItem={(targetDev, disk) => {
          const {
            device,
            source: {
              dev: { path: sdev = '' },
              file: { path: fpath = '' },
            },
            target: { dev: tdev },
          } = disk;

          let category = device;

          if (/cd/.test(device)) {
            category = 'optical';
          }

          return (
            <Grid alignItems="center" columnGap="1em" container>
              <Grid item xs>
                <FlexBox columnSpacing={0} row rowSpacing=".5em">
                  <BodyText noWrap>{capitalize(category)}:</BodyText>{' '}
                  <MonoText noWrap>{targetDev}</MonoText>
                </FlexBox>
                <MonoText noWrap>{sdev || fpath}</MonoText>
              </Grid>
              {category === 'optical' && (
                <Grid item>
                  <IconButton
                    onClick={() => {
                      setTarget(tdev);

                      changeIsoDialogRef.current?.setOpen(true);
                    }}
                    size="small"
                  >
                    <AlbumIcon />
                  </IconButton>
                </Grid>
              )}
              {category === 'disk' && (
                <Grid item>
                  <IconButton
                    onClick={() => {
                      setTarget(tdev);

                      growDiskDialogRef.current?.setOpen(true);
                    }}
                    size="small"
                  >
                    <ExpandIcon sx={{ rotate: '90deg' }} />
                  </IconButton>
                </Grid>
              )}
            </Grid>
          );
        }}
      />
      <DialogWithHeader header="Add disk" ref={addDiskDialogRef} showClose wide>
        <ServerAddDiskForm {...props} />
      </DialogWithHeader>
      <DialogWithHeader
        header={`${target}: grow disk`}
        ref={growDiskDialogRef}
        showClose
        wide
      >
        {target && <ServerAddDiskForm device={target} {...props} />}
      </DialogWithHeader>
      <DialogWithHeader
        header={`${target}: insert or eject ISO`}
        ref={changeIsoDialogRef}
        showClose
        wide
      >
        {target && <ServerChangeIsoForm device={target} {...props} />}
      </DialogWithHeader>
    </>
  );
};

export default ServerDiskList;
