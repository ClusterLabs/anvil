const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL?.replace(
  '/cgi-bin',
  '/api',
);

export default API_BASE_URL;
