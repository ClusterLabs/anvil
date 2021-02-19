import 'styled-components';

declare module 'styled-components' {
  export type DefaultTheme = {
    colors: {
      primary: string;
      secondary: string;
      tertiary: string;
    };
  };
}
