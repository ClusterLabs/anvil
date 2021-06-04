import Document, { DocumentInitialProps, DocumentContext } from 'next/document';
import { ServerStyleSheets as MaterialUiServerStyleSheets } from '@material-ui/styles';
// import { ServerStyleSheet as StyledComponentSheets } from 'styled-components';

class MyDocument extends Document {
  static async getInitialProps(
    ctx: DocumentContext,
  ): Promise<DocumentInitialProps> {
    const materialUiSheets = new MaterialUiServerStyleSheets();
    const originalRenderPage = ctx.renderPage;

    ctx.renderPage = () =>
      originalRenderPage({
        enhanceApp: (App) => (props) =>
          materialUiSheets.collect(
            <App
              /* eslint-disable react/jsx-props-no-spreading */
              {...props}
            />,
          ),
      });

    const initialProps = await Document.getInitialProps(ctx);

    return {
      ...initialProps,
      styles: (
        <>
          {initialProps.styles}
          {materialUiSheets.getStyleElement()}
        </>
      ),
    };
  }
}

export default MyDocument;
