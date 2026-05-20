const fs = require('fs');

const configPath = process.env.CONFIG_PATH || 'etc/mywebapp/config.json';

const readConfig = () => {
  try {
    const raw = fs.readFileSync(configPath, 'utf-8');
    return JSON.parse(raw);
  } catch (err) {
    console.log(`Fail to read config ${configPath}:`, err.message);
    process.exit(1);
  }
};

module.exports = readConfig();
