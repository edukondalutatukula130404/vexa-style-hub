module.exports = {
  apps: [
    {
      name: "vexa-backend",
      script: "./backend/server.js",
      instances: "max",
      exec_mode: "cluster",
      env: {
        NODE_ENV: "production",
        PORT: 5000,
      },
    },
  ],
};
