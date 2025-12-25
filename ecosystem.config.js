module.exports = {
  apps: [{
    name: 'christmas-tree-3d',
    script: 'pnpm',
    args: ['run', 'preview', '--', '--host', '0.0.0.0', '--port', process.env.PORT || '3000'],
    cwd: process.cwd(),
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    interpreter: 'none', // PM2 will use the script directly
    env: {
      NODE_ENV: 'production',
      PORT: process.env.PORT || '3000'
    }
  }]
};

