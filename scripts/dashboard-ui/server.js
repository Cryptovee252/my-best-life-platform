#!/usr/bin/env node

const http = require('http');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const httpRequest = require('http');

const ROOT_DIR = path.resolve(__dirname, '..', '..');
const LOG_DIR = path.join(ROOT_DIR, 'logs');
const TMP_DIR = path.join(ROOT_DIR, 'tmp');
const PUBLIC_DIR = path.join(__dirname, 'public');

fs.mkdirSync(LOG_DIR, { recursive: true });
fs.mkdirSync(TMP_DIR, { recursive: true });

const PORT = process.env.DASHBOARD_PORT ? Number(process.env.DASHBOARD_PORT) : 4550;

const state = {
  backend: { process: null, log: path.join(LOG_DIR, 'backend-dev.log') },
  frontend: { process: null, log: path.join(LOG_DIR, 'frontend-dev.log') },
};

function log(message) {
  console.log(`[dashboard] ${new Date().toISOString()} ${message}`);
}

function sendJson(res, status, payload) {
  const data = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data),
  });
  res.end(data);
}

function notFound(res) {
  res.statusCode = 404;
  res.end('Not Found');
}

function tailFile(filePath, maxLines = 200) {
  if (!fs.existsSync(filePath)) return '';
  const data = fs.readFileSync(filePath, 'utf8');
  const lines = data.split(/\r?\n/);
  return lines.slice(-maxLines).join('\n');
}

function runCommand(command, args = [], options = {}) {
  return new Promise((resolve) => {
    const child = spawn(command, args, { shell: true, ...options });
    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString();
    });

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString();
    });

    child.on('close', (code) => {
      resolve({ code, stdout, stderr });
    });
  });
}

function startProcess(target, command, args, cwd) {
  if (state[target].process) {
    throw new Error(`${target} already running`);
  }
  const logStream = fs.createWriteStream(state[target].log, { flags: 'a' });
  const child = spawn(command, args, { cwd, shell: true });
  state[target].process = child;

  child.stdout.on('data', (chunk) => {
    const text = chunk.toString();
    process.stdout.write(`[${target}] ${text}`);
    logStream.write(text);
  });

  child.stderr.on('data', (chunk) => {
    const text = chunk.toString();
    process.stderr.write(`[${target} err] ${text}`);
    logStream.write(text);
  });

  child.on('close', (code) => {
    log(`${target} exited with code ${code}`);
    logStream.write(`\n--- Process exited with code ${code} at ${new Date().toISOString()} ---\n`);
    logStream.end();
    state[target].process = null;
  });
}

function stopProcess(target) {
  const proc = state[target].process;
  if (!proc) {
    return false;
  }
  proc.kill();
  return true;
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function handleAction(action, body) {
  switch (action) {
    case 'start-backend':
      startProcess('backend', 'npm', ['run', 'dev'], path.join(ROOT_DIR, 'backend'));
      return { message: 'Backend starting...' };
    case 'stop-backend': {
      const stopped = stopProcess('backend');
      return { message: stopped ? 'Backend stopping...' : 'Backend was not running' };
    }
    case 'start-frontend':
      startProcess('frontend', 'npm', ['start', '--', '--web'], path.join(ROOT_DIR, 'frontend'));
      return { message: 'Frontend starting in web mode...' };
    case 'stop-frontend': {
      const stopped = stopProcess('frontend');
      return { message: stopped ? 'Frontend stopping...' : 'Frontend was not running' };
    }
    case 'restart-backend': {
      const stopped = stopProcess('backend');
      if (stopped) {
        await wait(1000);
      }
      startProcess('backend', 'npm', ['run', 'dev'], path.join(ROOT_DIR, 'backend'));
      return { message: 'Backend restart triggered' };
    }
    case 'restart-frontend': {
      const stopped = stopProcess('frontend');
      if (stopped) {
        await wait(1000);
      }
      startProcess('frontend', 'npm', ['start', '--', '--web'], path.join(ROOT_DIR, 'frontend'));
      return { message: 'Frontend restart triggered' };
    }
    case 'prisma-push': {
      const result = await runCommand('npx', ['prisma', 'db', 'push'], { cwd: path.join(ROOT_DIR, 'backend') });
      return { message: 'Prisma db push finished', ...result };
    }
    case 'api-health': {
      const payload = await new Promise((resolve) => {
        const req = httpRequest.request('http://localhost:5000/api/health', (res) => {
          let body = '';
          res.on('data', (chunk) => { body += chunk; });
          res.on('end', () => {
            resolve({ code: res.statusCode, stdout: body });
          });
        });
        req.on('error', (err) => {
          resolve({ code: 1, stderr: err.message });
        });
        req.end();
      });
      return { message: 'Health check completed', ...payload };
    }
    case 'run-tests': {
      const backend = await runCommand('npm', ['test'], { cwd: path.join(ROOT_DIR, 'backend') });
      const frontend = await runCommand('npm', ['test'], { cwd: path.join(ROOT_DIR, 'frontend') });
      return { message: 'Tests completed', backend, frontend };
    }
    case 'build-frontend': {
      const result = await runCommand('npm', ['run', 'build:web'], { cwd: path.join(ROOT_DIR, 'frontend') });
      return { message: 'Frontend build completed', ...result };
    }
    case 'git-status': {
      const result = await runCommand('git', ['status', '-sb'], { cwd: ROOT_DIR });
      return { message: 'Git status', ...result };
    }
    case 'git-commit-push': {
      const commitMessage = (body && body.message) ? body.message.trim() : '';
      if (!commitMessage) {
        throw new Error('Commit message is required');
      }
      const add = await runCommand('git', ['add', '.'], { cwd: ROOT_DIR });
      const commit = await runCommand('git', ['commit', '-m', commitMessage], { cwd: ROOT_DIR });
      let push = { code: 0, stdout: '', stderr: '' };
      if (commit.code === 0) {
        push = await runCommand('git', ['push'], { cwd: ROOT_DIR });
      }
      return { message: 'Git commit/push finished', add, commit, push };
    }
    case 'deploy': {
      const scriptPath = path.join(ROOT_DIR, 'deploy-to-vps.sh');
      const result = await runCommand('bash', [scriptPath], { cwd: ROOT_DIR });
      return { message: 'Deployment script finished', ...result };
    }
    case 'docker-up': {
      const result = await runCommand('docker-compose', ['up', '-d', 'db'], { cwd: ROOT_DIR });
      return { message: 'Docker compose up finished', ...result };
    }
    case 'docker-down': {
      const result = await runCommand('docker-compose', ['down'], { cwd: ROOT_DIR });
      return { message: 'Docker compose down finished', ...result };
    }
    case 'docker-status': {
      const result = await runCommand('docker-compose', ['ps'], { cwd: ROOT_DIR });
      return { message: 'Docker compose status', ...result };
    }
    default:
      throw new Error(`Unknown action: ${action}`);
  }
}

function isRunning(target) {
  return Boolean(state[target].process);
}

async function requestHandler(req, res) {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === 'GET' && url.pathname === '/') {
    const indexPath = path.join(PUBLIC_DIR, 'index.html');
    const content = fs.readFileSync(indexPath);
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(content);
  }

  if (req.method === 'GET' && url.pathname.startsWith('/static/')) {
    const filePath = path.join(PUBLIC_DIR, url.pathname.replace('/static/', ''));
    if (!fs.existsSync(filePath)) {
      return notFound(res);
    }
    const ext = path.extname(filePath);
    const type = ext === '.css' ? 'text/css' : ext === '.js' ? 'application/javascript' : 'text/plain';
    res.writeHead(200, { 'Content-Type': type });
    return res.end(fs.readFileSync(filePath));
  }

  if (req.method === 'GET' && url.pathname === '/api/status') {
    return sendJson(res, 200, {
      backend: { running: isRunning('backend') },
      frontend: { running: isRunning('frontend') },
      backendLog: tailFile(state.backend.log),
      frontendLog: tailFile(state.frontend.log),
    });
  }

  if (req.method === 'POST' && url.pathname === '/api/action') {
    let body = '';
    req.on('data', (chunk) => { body += chunk; });
    req.on('end', async () => {
      try {
        const parsed = body ? JSON.parse(body) : {};
        const { action } = parsed;
        if (!action) {
          throw new Error('Action is required');
        }
        const result = await handleAction(action, parsed);
        sendJson(res, 200, { success: true, result });
      } catch (error) {
        log(`Action error: ${error.message}`);
        sendJson(res, 400, { success: false, error: error.message });
      }
    });
    return;
  }

  notFound(res);
}

const server = http.createServer(requestHandler);

server.listen(PORT, () => {
  log(`Dashboard running at http://localhost:${PORT}`);
});

function cleanup() {
  log('Shutting down dashboard...');
  Object.entries(state).forEach(([key, value]) => {
    if (value.process) {
      log(`Stopping ${key} process`);
      value.process.kill();
      value.process = null;
    }
  });
  server.close(() => process.exit(0));
}

process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);
