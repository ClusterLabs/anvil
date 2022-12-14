import Document, { DocumentInitialProps, DocumentContext } from 'next/document';
import createEmotionServer from '@emotion/server/create-instance';

import createEmotionCache from '../lib/create_emotion_cache/createEmotionCache';

class MyDocument extends Document {
  static async getInitialProps(
    ctx: DocumentContext,
  ): Promise<DocumentInitialProps> {
    const originalRenderPage = ctx.renderPage;

    const emotionCache = createEmotionCache();
    const { extractCriticalToChunks } = createEmotionServer(emotionCache);

    ctx.renderPage = () =>
      originalRenderPage({
        // Temporary; the implicit type of App doesn't include the prop "emotionCache" thus typescript will complain.
        // Find a way to extend the implicit type to add the cache property.
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        enhanceApp: (App: any) =>
          function EnhanceApp(props) {
            return <App emotionCache={emotionCache} {...props} />;
          },
      });

    const initialProps = await Document.getInitialProps(ctx);

    const emotionStyles = extractCriticalToChunks(initialProps.html);
    const emotionStyleTags = emotionStyles.styles.map((style) => (
      <style
        data-emotion={`${style.key} ${style.ids.join(' ')}`}
        key={style.key}
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{ __html: style.css }}
      />
    ));

    return {
      ...initialProps,
      styles: (
        <>
          {initialProps.styles}
          {emotionStyleTags}
        </>
      ),
    };
  }
}

export default MyDocument;
