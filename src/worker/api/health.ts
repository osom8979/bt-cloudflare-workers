import {Hono} from 'hono';

const health = new Hono<{Bindings: Env}>();

health.get('/', c => c.json({status: 'ok', environment: c.env.ENVIRONMENT}));

export {health};
