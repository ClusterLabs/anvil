import MuiAssignmentIcon from '@mui/icons-material/Assignment';
import MuiAppBar from '@mui/material/AppBar';
import MuiBox from '@mui/material/Box';
import MuiButton from '@mui/material/Button';
import MuiIconButton from '@mui/material/IconButton';
import styled from '@mui/material/styles/styled';
import { useRef, useState } from 'react';

import { BORDER_RADIUS, OLD_ICON, RED } from '../lib/consts/DEFAULT_THEME';

import AnvilDrawer from './AnvilDrawer';
import FlexBox from './FlexBox';
import IconWithIndicator, {
  IconWithIndicatorForwardedRefContent,
} from './IconWithIndicator';
import JobSummary, { JobSummaryForwardedRefContent } from './JobSummary';

const PREFIX = 'Header';

const classes = {
  input: `${PREFIX}-input`,
  barElement: `${PREFIX}-barElement`,
  iconBox: `${PREFIX}-iconBox`,
  searchBar: `${PREFIX}-searchBar`,
  icons: `${PREFIX}-icons`,
};

const StyledAppBar = styled(MuiAppBar)(({ theme }) => ({
  paddingTop: theme.spacing(0.5),
  paddingBottom: theme.spacing(0.5),
  paddingLeft: theme.spacing(3),
  paddingRight: theme.spacing(3),
  borderBottom: 'solid 1px',
  borderBottomColor: RED,
  position: 'static',

  [`& .${classes.input}`]: {
    height: '2.8em',
    width: '30vw',
    backgroundColor: theme.palette.secondary.main,
    borderRadius: BORDER_RADIUS,
  },

  [`& .${classes.barElement}`]: {
    padding: 0,
  },

  [`& .${classes.iconBox}`]: {
    [theme.breakpoints.down('sm')]: {
      display: 'none',
    },
  },

  [`& .${classes.searchBar}`]: {
    [theme.breakpoints.down('sm')]: {
      flexGrow: 1,
      paddingLeft: '15vw',
    },
  },

  [`& .${classes.icons}`]: {
    paddingLeft: '.1em',
    paddingRight: '.1em',
  },
}));

const Header: React.FC = () => {
  const jobIconRef = useRef<IconWithIndicatorForwardedRefContent>({});
  const jobSummaryRef = useRef<JobSummaryForwardedRefContent>({});

  const [open, setOpen] = useState(false);

  const toggleDrawer = (): void => setOpen(!open);

  return (
    <>
      <StyledAppBar>
        <MuiBox
          display="flex"
          justifyContent="space-between"
          flexDirection="row"
        >
          <FlexBox row>
            <MuiButton onClick={toggleDrawer}>
              <img alt="" src="/pngs/logo.png" width="160" height="40" />
            </MuiButton>
          </FlexBox>
          <FlexBox className={classes.iconBox} row spacing={0}>
            <MuiBox>
              <MuiIconButton
                onClick={({ currentTarget }) => {
                  jobSummaryRef.current.setAnchor?.call(null, currentTarget);
                  jobSummaryRef.current.setOpen?.call(null, true);
                }}
                sx={{ color: OLD_ICON, padding: '0 .1rem' }}
              >
                <IconWithIndicator icon={MuiAssignmentIcon} ref={jobIconRef} />
              </MuiIconButton>
            </MuiBox>
          </FlexBox>
        </MuiBox>
      </StyledAppBar>
      <AnvilDrawer open={open} setOpen={setOpen} />
      <JobSummary
        onFetchSuccessAppend={(jobs) => {
          jobIconRef.current.indicate?.call(null, Object.keys(jobs).length > 0);
        }}
        ref={jobSummaryRef}
      />
    </>
  );
};

export default Header;
