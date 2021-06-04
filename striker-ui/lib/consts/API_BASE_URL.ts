import IS_DEV_ENV from './IS_DEV_ENV';

const API_BASE_URL = IS_DEV_ENV
  ? process.env.DEVELOPMENT_API_BASE_URL
  : process.env.PRODUCTION_API_BASE_URL;

export default API_BASE_URL;
