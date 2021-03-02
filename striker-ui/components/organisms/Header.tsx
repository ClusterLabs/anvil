import { FunctionComponent } from 'react';
import AppBar from '@material-ui/core/AppBar';
import { makeStyles, createStyles } from '@material-ui/core/styles';
import Image from 'next/image';

// import DEFAULT_THEME from '../../lib/consts/DEFAULT_THEME';

const useStyles = makeStyles((theme) =>
  createStyles({
    appBar: {
      paddingTop: theme.spacing(0.5),
      paddingBottom: theme.spacing(0.5),
      paddingLeft: theme.spacing(3),
      paddingRight: theme.spacing(0.5),
    },
  }),
);

const Header: FunctionComponent = () => {
  const classes = useStyles();
  return (
    <AppBar position="static" className={classes.appBar}>
      <div>
        <Image src="/pngs/logo.png" width="160" height="40" />
      </div>
    </AppBar>
    /* <StyledRightContainer>
        <div>
          <Image src="/pngs/files_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/tasks_no-jobs_icon.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/configure_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/striker_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/anvil_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/email_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/users_icon_on.png" width="40" height="40" />
        </div>
        <div>
          <Image src="/pngs/help_icon_on.png" width="40" height="40" />
        </div>
      </StyledRightContainer>
    </StyledHeader> */
  );
};

export default Header;
