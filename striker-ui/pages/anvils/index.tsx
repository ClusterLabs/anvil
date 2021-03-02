import { GetServerSidePropsResult, InferGetServerSidePropsType } from 'next';
import { createMuiTheme, ThemeProvider } from '@material-ui/core/styles';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import Button from '../../components/atoms/Button';
import Header from '../../components/organisms/Header';
import List from '../../components/molecules/List';
import PageCenterContainer from '../../components/organisms/PageCenterContainer';

import fetchJSON from '../../lib/fetchers/fetchJSON';

import 'typeface-muli';

const theme = createMuiTheme({
  palette: {
    primary: {
      main: '#343434',
      light: '#3E78B2',
    },
    secondary: {
      main: '#343434',
    },
  },
  typography: {
    fontFamily: 'Muli',
    fontSize: 14,
  },
  overrides: {
    MuiRadio: {
      root: {
        color: '#222222',
      },
      colorSecondary: {
        '&$checked': {
          color: '#555555',
        },
      },
    },
  },
});

export async function getServerSideProps(): Promise<
  GetServerSidePropsResult<AnvilList>
> {
  return {
    props: await fetchJSON(`${API_BASE_URL}/api/anvils`),
  };
}

function DemoAnvilList({
  anvils,
}: InferGetServerSidePropsType<typeof getServerSideProps>): JSX.Element {
  return (
    <ThemeProvider theme={theme}>
      <Header />
      <PageCenterContainer>
        <List labelText="List of Anvils">
          {anvils.map(
            (anvil: AnvilListItem): JSX.Element => (
              <Button
                key={anvil.uuid}
                imageProps={{ src: '/pngs/anvil_icon_on.png' }}
                labelProps={{ text: anvil.uuid }}
                linkProps={{ href: `/anvils/${anvil.uuid}` }}
              />
            ),
          )}
        </List>
      </PageCenterContainer>
    </ThemeProvider>
  );
}

export default DemoAnvilList;
